make_verification_outputs <- function(root = repo_root()) {
  psi <- read_csv_release(file.path(root, "data", "processed", "reference", "weekly_acoustic_opportunity.csv"))
  exp <- read_csv_release(file.path(root, "data", "processed", "reference", "weekly_acoustic_exposure.csv"))
  support <- read_csv_release(file.path(root, "data", "processed", "reference", "prediction_support_classes.csv"))
  effects <- read_csv_release(file.path(root, "data", "processed", "reference", "model_effects.csv"))

  ensure_dir(file.path(root, "outputs", "figures"))
  pdf_path <- file.path(root, "outputs", "figures", "verification_overview.pdf")
  grDevices::pdf(pdf_path, width = 10, height = 7, family = "Helvetica")
  old <- graphics::par(no.readonly = TRUE)
  on.exit({graphics::par(old); grDevices::dev.off()}, add = TRUE)
  graphics::par(mfrow = c(2, 2), mar = c(4, 4, 2.5, 1), las = 1, bty = "l")

  graphics::plot(psi$calendar_week, psi$spatial_median_pct, type = "l", lwd = 2.5, col = "#176B73",
                 xlab = "Annual week", ylab = "Weekly acoustic opportunity (%)", main = "Annual opportunity")
  graphics::polygon(c(psi$calendar_week, rev(psi$calendar_week)),
                    c(psi$spatial_q10_pct, rev(psi$spatial_q90_pct)),
                    col = grDevices::adjustcolor("#72B7C2", 0.25), border = NA)
  graphics::lines(psi$calendar_week, psi$spatial_median_pct, lwd = 2.5, col = "#176B73")

  graphics::plot(exp$calendar_week, exp$area_weighted_mean_pct, type = "l", lwd = 2.5, col = "#D87332",
                 xlab = "Annual week", ylab = "Sampled-minute exposure (%)", main = "City mapping subset")

  cols <- c("#16838A", "#E8A03B", "#D9DEE1", "#A5ADB1")
  graphics::barplot(support$n_hex, names.arg = support$support_class, las = 2, col = cols, border = NA,
                    ylab = "HEX cells", main = "Prediction support", cex.names = 0.7)

  mu <- effects[effects$component == "positive_day_minute_probability", ]
  graphics::plot(mu$median, seq_len(nrow(mu)), xlim = range(c(mu$q025, mu$q975)), pch = 21,
                 bg = "#D87332", col = "#D87332", yaxt = "n", xlab = "Standardised logit coefficient", ylab = "",
                 main = "Calling-density effects")
  graphics::segments(mu$q025, seq_len(nrow(mu)), mu$q975, seq_len(nrow(mu)), col = "#176B73", lwd = 2)
  graphics::axis(2, at = seq_len(nrow(mu)), labels = mu$term, las = 2, cex.axis = 0.75)
  graphics::abline(v = 0, lty = 2, col = "#7C8D93")

  invisible(pdf_path)
}

