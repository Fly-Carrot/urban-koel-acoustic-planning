# Stan model source

These four Stan programs are the exact source files used by the final joint daily and hourly calling-density lineage. They are included for model transparency and code review; compiled binaries, chain CSV files and private-input adapters are excluded.

| File | Role |
|---|---|
| `462_joint_occupancy_hurdle_intensity.stan` | linked weekly opportunity, daily detection hurdle and positive-day minute count model |
| `463_joint_intensity_host_season_compare.stan` | host-informed and seasonal daily calling-density comparison |
| `470_conditional_hourly_density.stan` | modular cyclic hourly calling-density extension |
| `471_integrated_hourly_joint.stan` | integrated confirmation model linking hourly density to the weekly and daily layers |

The public verification profile consumes aggregate posterior summaries and does not compile these programs. See `docs/model_registry.md` and `docs/scientific_boundaries.md` for interpretation limits.
