// b_np_pcpi_eu_ko.stan

data {
  // Metabolism distributions
  real GPP_daily_mu;
  real GPP_daily_sigma;
  real ER_daily_mu;
  real ER_daily_sigma;
  real K600_daily_mu;
  real K600_daily_sigma;
  
  // Error distributions
  real err_proc_acor_phi_min;
  real err_proc_acor_phi_max;
  real err_proc_acor_sigma_min;
  real err_proc_acor_sigma_max;
  real err_proc_iid_sigma_min;
  real err_proc_iid_sigma_max;
  
  // Daily data
  int <lower=0> n;
  real DO_obs_1;
  
  // Data
  vector [n] DO_obs;
  vector [n] DO_sat;
  vector [n] frac_GPP;
  vector [n] frac_ER;
  vector [n] frac_D;
  vector [n] depth;
  vector [n] KO2_conv;
}

transformed data {
  vector [n-1] coef_GPP;
  vector [n-1] coef_ER;
  vector [n-1] coef_K600_full;
  vector [n-1] dDO_obs;
  
  for(i in 1:(n-1)) {
    // Coefficients by lag (e.g., frac_GPP[i] applies to the DO step from i to i+1)
    coef_GPP[i]  <- frac_GPP[i] / depth[i];
    coef_ER[i]   <- frac_ER[ i] / depth[i];
    coef_K600_full[i] <- KO2_conv[i] * frac_D[i] * 
      (DO_sat[i] - DO_obs[i]);
    // dDO observations
    dDO_obs[i] <- DO_obs[i+1] - DO_obs[i];
  }
}

parameters {
  real GPP_daily;
  real ER_daily;
  real K600_daily;
  
  vector [n-1] err_proc_acor_inc;
  
  real <lower=err_proc_acor_phi_min,   upper=err_proc_acor_phi_max>   err_proc_acor_phi;
  real <lower=err_proc_acor_sigma_min, upper=err_proc_acor_sigma_max> err_proc_acor_sigma;
  real <lower=err_proc_iid_sigma_min,  upper=err_proc_iid_sigma_max>  err_proc_iid_sigma;
}

transformed parameters {
  vector [n-1] dDO_mod;
  vector [n-1] err_proc_acor;
  
  // Model DO time series
  // * Euler version
  // * no observation error
  // * IID and autocorrelated process error
  // * reaeration depends on DO_obs
  
  err_proc_acor[1] <- err_proc_acor_inc[1];
  for(i in 1:(n-2)) {
    err_proc_acor[i+1] <- err_proc_acor_phi * err_proc_acor[i] + err_proc_acor_inc[i+1];
  }
  
  // dDO model
  dDO_mod <- 
    err_proc_acor +
    GPP_daily * coef_GPP +
    ER_daily * coef_ER +
    K600_daily * coef_K600_full;
}

model {
  // Independent, identically distributed process error
  for (i in 1:(n-1)) {
    dDO_obs[i] ~ normal(dDO_mod[i], err_proc_iid_sigma);
  }
  err_proc_iid_sigma ~ uniform(err_proc_iid_sigma_min, err_proc_iid_sigma_max);
  
  // Autocorrelated process error
  for(i in 1:(n-1)) {
    err_proc_acor_inc[i] ~ normal(0, err_proc_acor_sigma);
  }
  // Autocorrelation (phi) & SD (sigma) of the process errors
  err_proc_acor_phi ~ uniform(err_proc_acor_phi_min, err_proc_acor_phi_max);
  err_proc_acor_sigma ~ uniform(err_proc_acor_sigma_min, err_proc_acor_sigma_max);
  
  // Daily metabolism values
  GPP_daily ~ normal(GPP_daily_mu, GPP_daily_sigma);
  ER_daily ~ normal(ER_daily_mu, ER_daily_sigma);
  K600_daily ~ normal(K600_daily_mu, K600_daily_sigma);
}
