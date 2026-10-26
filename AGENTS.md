# AGENTS.md

Tutorial project (UMD MSML610) on causal discovery with Tetrad/py-tetrad. No package, tests, lint/typecheck config, or CI; the deliverables are two notebook + report pairs.

## Layout and conventions
- `tetrad.API.ipynb` / `tetrad.API.md`: Knowledge, TetradSearch (FGES, RFCI), raw JPype (IMaGES-BOSS), simulation, CausalPerceptronNetwork.
- `tetrad.example.ipynb` / `tetrad.example.md`: end-to-end Twitter-sentiment + stock-price analysis.
- Each `.md` is a prose report, not an export of its notebook. Code or claim changes mean updating both, and keeping the `<!-- toc -->` ... `<!-- tocstop -->` lists in the `.md` files and `README.md` in sync.
- `tetrad_utils.py` is an empty placeholder; don't assume helpers exist there.
- `tmp.build/` is a build-time copy of `dockerfiles/`, not a second source tree. Also ignore `.ipynb_checkpoints/` and `docker_build.log`.

## Running
There is a single image, `tetrad_analysis`, built and run locally only; nothing is pushed to a registry. On Windows run these scripts with **Git Bash, not WSL**: WSL paths under `/mnt/c` are shadowed by Docker Desktop bind mounts, so `/data` ends up showing hash-named mount folders instead of the project. `docker_jupyter.sh` resolves paths with `pwd -P` and `cygpath` for this reason.
- `cd dockerfiles && bash docker_build.sh` builds `tetrad_analysis` (Ubuntu 24.04, JDK 21, Python 3.12, Jupyter). This script still requires `dockerfiles/` as cwd (`source ./utils.sh` is relative). The image name lives in `docker_name.sh` and must stay lowercase, since Docker rejects mixed-case repository names.
- `bash dockerfiles/docker_jupyter.sh` serves Jupyter at http://localhost:8888 with no token. The repo root is mounted at `/data` (Jupyter starts there); `dockerfiles/` is at `/curr_dir`. The container is named `tetrad_analysis`, so stop any running one before relaunching.
- `-p <port>` maps that host port to the container's fixed 8888.
- For a shell from PowerShell: `docker run --rm -ti -v "${PWD}:/data" tetrad_analysis bash`.
- `docker_build.sh` and `docker_jupyter.sh` are the only docker entry points; the bash/exec/clean/push helpers were removed.
- `tornado==6.1`, `jupyter-client==7.3.2`, and `setuptools<81` are pinned deliberately to avoid a known Jupyter/zmq crash and a `pkg_resources` import error in `jupyter-contrib-core`; don't bump them casually.

## Notebook gotchas
- The image does not contain py-tetrad, JPype, or `datasets`; the first cell of each notebook pip-installs them, including py-tetrad from git master. Reruns therefore need network access and can break without any repo change.
- `tetrad.API.ipynb` uses plain `%pip` (last executed in a Windows Anaconda env); inside the Docker image it needs `--break-system-packages` like `tetrad.example.ipynb` uses.
- Example data is read directly from `hf://datasets/...` on HuggingFace; no data files are committed.
- Outside Docker, JPype requires JDK 21+ discoverable via `JAVA_HOME`.
- Outputs are committed and contain machine-specific paths/versions. Re-executing notebooks rewrites large outputs, so keep that diff intentional.
- Results are not fully reproducible: some runs use random seeds (e.g. CausalPerceptronNetwork with `seed=None`), so graphs and scores can change between runs.
- Verification is manual: execute the affected notebook top to bottom. There is no test or lint command.
