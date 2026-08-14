functions {
  real zero_truncated_beta_binomial_lpmf(
      int k, int n, real mu, real phi) {
    real alpha_bb = mu * phi;
    real beta_bb = (1 - mu) * phi;
    real log_p0 = beta_binomial_lpmf(0 | n, alpha_bb, beta_bb);
    return beta_binomial_lpmf(k | n, alpha_bb, beta_bb)
           - log1m_exp(log_p0);
  }
}

data {
  int<lower=1> G;
  int<lower=1> D;
  int<lower=1> S;
  int<lower=1> P_occ;
  int<lower=1> P_det;
  int<lower=1> P_int;
  matrix[G, P_occ] X_occ;
  matrix[D, P_det] X_det;
  matrix[D, P_int] X_int;
  array[D] int<lower=1, upper=S> site_id;
  array[D] int<lower=0, upper=1> detected;
  array[D] int<lower=0> k;
  array[D] int<lower=1> n;
  array[G] int<lower=1, upper=D> start_day;
  array[G] int<lower=1, upper=D> end_day;
  array[G] int<lower=0, upper=1> any_positive;
  vector[P_det] x_det_reference;
  int<lower=1> n_reference;
}

parameters {
  vector[P_occ] beta_occ;
  vector[P_det] alpha_det;
  vector[P_int] gamma_int;
  vector[S] site_det_raw;
  real<lower=0> sigma_det;
  real<lower=log(0.01), upper=log(1e5)> log_phi;
}

transformed parameters {
  vector[S] site_det = sigma_det * (
    site_det_raw - rep_vector(mean(site_det_raw), S)
  );
  real<lower=0> phi = exp(log_phi);
}

model {
  beta_occ ~ normal(0, 2.25);
  alpha_det ~ normal(0, 2.25);
  gamma_int[1] ~ normal(-4, 3);
  if (P_int > 1) {
    gamma_int[2:P_int] ~ normal(0, 2);
  }
  site_det_raw ~ std_normal();
  sigma_det ~ normal(0, 1);
  log_phi ~ normal(log(50), 1.5);

  for (g in 1:G) {
    real eta_occ = X_occ[g] * beta_occ;
    real log_lik_if_present = 0;
    for (r in start_day[g]:end_day[g]) {
      real eta_det = X_det[r] * alpha_det + site_det[site_id[r]];
      if (detected[r] == 1) {
        real mu_int = fmin(
          1 - 1e-9,
          fmax(1e-9, inv_logit(X_int[r] * gamma_int))
        );
        log_lik_if_present += bernoulli_logit_lpmf(1 | eta_det);
        log_lik_if_present += zero_truncated_beta_binomial_lpmf(
          k[r] | n[r], mu_int, phi
        );
      } else {
        log_lik_if_present += bernoulli_logit_lpmf(0 | eta_det);
      }
    }
    if (any_positive[g] == 1) {
      target += bernoulli_logit_lpmf(1 | eta_occ)
                + log_lik_if_present;
    } else {
      target += log_sum_exp(
        bernoulli_logit_lpmf(0 | eta_occ),
        bernoulli_logit_lpmf(1 | eta_occ) + log_lik_if_present
      );
    }
  }
}

generated quantities {
  vector[G] log_lik_group;

  for (g in 1:G) {
    real eta_occ = X_occ[g] * beta_occ;
    real log_lik_if_present = 0;
    for (r in start_day[g]:end_day[g]) {
      real eta_det = X_det[r] * alpha_det + site_det[site_id[r]];
      if (detected[r] == 1) {
        real mu_int = fmin(
          1 - 1e-9,
          fmax(1e-9, inv_logit(X_int[r] * gamma_int))
        );
        log_lik_if_present += bernoulli_logit_lpmf(1 | eta_det);
        log_lik_if_present += zero_truncated_beta_binomial_lpmf(
          k[r] | n[r], mu_int, phi
        );
      } else {
        log_lik_if_present += bernoulli_logit_lpmf(0 | eta_det);
      }
    }
    if (any_positive[g] == 1) {
      log_lik_group[g] =
        bernoulli_logit_lpmf(1 | eta_occ) + log_lik_if_present;
    } else {
      log_lik_group[g] = log_sum_exp(
        bernoulli_logit_lpmf(0 | eta_occ),
        bernoulli_logit_lpmf(1 | eta_occ) + log_lik_if_present
      );
    }
  }
}
