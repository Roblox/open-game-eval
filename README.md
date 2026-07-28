# OpenGameEval

OpenGameEval is an evaluation framework for testing LLMs on Roblox game development tasks. This repository contains open-sourced evaluation scripts and tools for running automated assessments in the Roblox Studio environment.

## LLM Leaderboard

The LLM Leaderboard summarizes benchmark results and progress for all evaluated Large Language Models in this repository.
[LLM_LEADERBOARD.md](./LLM_LEADERBOARD.md)

## Prerequisites

### 1. Roblox Account
You'll need a Roblox account. If you don't have one, create a free account at [roblox.com](https://www.roblox.com).

### 2. OpenCloud API Key
To interact with the OpenGameEval API, you need to create an OpenCloud API key:

1. Navigate to [Creator Hub](https://create.roblox.com) and log in. Make sure you are viewing as user, not group.
2. Go to **All tools** (or **OpenCloud**) > **API Keys**
3. Create a new key with:
   - **Access Permissions**: `studio-evaluations`
   - **Operations**: `create`
   - Set an expiration date (recommended: 90 days)
4. Save and copy the generated key, which will be used as <OPEN_GAME_EVAL_API_KEY> in following commands.

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/Roblox/open-game-eval.git
cd open-game-eval
```

### 2. Install uv (one-time setup)
The project uses `uv` for dependency management. Install dependencies:
```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with Homebrew
brew install uv

# Or with pip
pip install uv
```

### 3. Run Your Evaluation
**Important:** You must provide your own LLM credentials (`--llm-name` and `--llm-api-key`) to run evaluations.

You may save your API keys in a file named `.env`. See `.env.example` for a sample.

```bash
# Set envvar
export OPEN_GAME_EVAL_API_KEY=<your-open-game-eval-api-key>
export ANTHROPIC_API_KEY=<your-anthropic-api-key>

# Pass in OpenGameEval API key and LLM API key (required)
uv run invoke_eval.py --files "Evals/001_make_cars_faster.lua" \
  --api-key $OPEN_GAME_EVAL_API_KEY \
  --llm-name "claude" \
  --llm-api-key $ANTHROPIC_API_KEY
```

It should show the status being "submitted" with a url, through which you can check the status of the eval with the Roblox account that owns the API key logged in. 
```bash
Evals/001_make_cars_faster.lua                      : Submitted - https://apis.roblox.com/open-eval-api/v1/eval-records/b7647585-5e1f-46b5-a8be-797539b65cc5
```

It is common for an eval to take 3-4 minutes to run and gather results. The script polls result every 10 seconds and print a status update every 30 seconds.

Once completed, it will return whether the eval run is successful or not. The default timeout is 10 minutes.

```bash
Evals/001_make_cars_faster.lua                      : Success
Success rate: 100.00% (1/1)  
```

## Understanding Eval Result
After eval completed, a result object will be returned as a part of http response. It is accessible through `https://apis.roblox.com/open-eval-api/v1/eval-records/{jobId}`

The eval is considered as a pass only if all checks are passed.
```
"results": [
      {
        "mode": "[EDIT]",
        "result": {
          "passes": 1,
          "fails": 0,
          "checks": 1,
          "warning": "",
          "error": "",
          "interruptions": []
        }
      }
    ],
```
### Eval result fields
- `passes`: Number of checks passed.
- `fails`: Number of checks failed.
- `checks`: Total number of checks. Equals to passes + fails.
- `warnings`: Number of warnings received when running the eval.
- `error`: Number of errors received when running the eval.

## Task annotations

Every task file carries three optional annotation fields. They do not affect grading,
and nothing in them is shown to the model. They record what a competent solution is
expected to do, so that a run's *trajectory* can be scored against the task rather
than only its final verdict.

```lua
local eval: BaseEval = {
    scenario_name = "080_surburban_school_lights_on",
    -- prompt, place, checks ...
    expected_tool_calls = {
        "game_tree", -- search for lights
        "inspect_instance",
        "execute_luau",
    },
    expected_script_instances = {},
    expected_non_script_instances = {
        "game.Workspace.School.Lights",
    },
}
```

- **`expected_tool_calls`** the tools a competent solution is expected to use. Present
  and non-empty on every task. Entries may carry a trailing Lua comment explaining the
  intent, as above.
- **`expected_script_instances`** script instances (`Script`, `LocalScript`,
  `ModuleScript`) whose contents a solution has to read or modify.
- **`expected_non_script_instances`** the remaining instances a solution depends on,
  such as the folder, model, or part it has to locate and change.

Unlike `expected_tool_calls`, the two instance fields are not populated on every task.
An empty table means the task was not annotated, not that the task has no dependencies,
so a task with an empty field is better excluded from an analysis than counted as zero.

Instance paths are written from the datamodel root, `game.Workspace.School.Lights`,
and use bracket indexing where a name contains a space,
`game.Workspace["Urban House"].Chimney`. A path names the instance a solution must
reach, not necessarily one it must modify: for a task whose prompt says to change
every light in a building, the annotation names the containing folder, and the
solution is expected to walk it.

## More Usage

### Running Multiple Evaluations
**⚠️ Please beware of rate limit when running multiple evals. See "Rate Limit" section for more informaiton.**

```bash
# Set envvar
export OPEN_GAME_EVAL_API_KEY=<your-open-game-eval-api-key>
export ANTHROPIC_API_KEY=<your-anthropic-api-key>

# Run all evaluations
uv run invoke_eval.py --files "Evals/*.lua" --api-key $OPEN_GAME_EVAL_API_KEY --llm-name "claude" --llm-api-key $ANTHROPIC_API_KEY

# Run specific pattern
uv run invoke_eval.py --files "Evals/0*_*.lua" --api-key $OPEN_GAME_EVAL_API_KEY --llm-name "claude" --llm-api-key $ANTHROPIC_API_KEY

# Run with concurrency limit
uv run invoke_eval.py --files "Evals/*.lua" --max-concurrent 5 --api-key $OPEN_GAME_EVAL_API_KEY --llm-name "claude" --llm-api-key $ANTHROPIC_API_KEY
```

### Using Custom LLM Models
Please make sure the `LLM_API_KEY` is the correct key corresponding to the model provider.

```bash
# Set envvar
export OPEN_GAME_EVAL_API_KEY=<your-open-game-eval-api-key>
export GEMINI_API_KEY=<your-gemini-api-key>
export ANTHROPIC_API_KEY=<your-anthropic-api-key>
export OPENAI_API_KEY=<your-openai-api-key>

# With Gemini
uv run invoke_eval.py --files "Evals/001_make_cars_faster.lua" \
  --api-key $OPEN_GAME_EVAL_API_KEY \
  --llm-name "gemini" \
  --llm-model-version "gemini-2.5-pro" \
  --llm-api-key $GEMINI_API_KEY

# With Claude
uv run invoke_eval.py --files "Evals/001_make_cars_faster.lua" \
  --api-key $OPEN_GAME_EVAL_API_KEY \
  --llm-name "claude" \
  --llm-model-version "claude-sonnet-4-5-20250929" \
  --llm-api-key $ANTHROPIC_API_KEY

# With OpenAI
uv run invoke_eval.py --files "Evals/001_make_cars_faster.lua" \
  --api-key $OPEN_GAME_EVAL_API_KEY \
  --llm-name "openai" \
  --llm-model-version "gpt-5" \
  --llm-api-key $OPENAI_API_KEY
```

## Command Line Options

```bash
uv run invoke_eval.py [OPTIONS]

Required Options:
  --files TEXT [TEXT ...]    Lua files to evaluate (supports wildcards)
  --api-key TEXT             Open Cloud API key studio-evaluation (or set OPEN_GAME_EVAL_API_KEY env var)

Required if running evals through LLM (not using reference mode):
  --llm-name TEXT            Name of provider: claude | gemini | openai (REQUIRED)
  --llm-api-key TEXT         LLM API key (REQUIRED, or set LLM_API_KEY env var)

Optional:
  --llm-model-version TEXT   LLM model version, e.g. claude-4-sonnet-20250514
  --llm-url TEXT             LLM endpoint URL. Not yet supported, please put a placeholder string here.
  --max-concurrent INTEGER   Maximum concurrent evaluations
  --use-reference-mode       Use reference mode for evaluation. This skips LLM and uses reference code for debugging eval contributions.
  --verbose-headers          Output HTTP request and response headers for debugging
```

**Note:** `--llm-name` and `--llm-api-key` are required to ensure evaluations use your own LLM API key. The only exception is `--use-reference-mode`, which doesn't call an LLM.

Available model-versions:
- For Gemini models (provider-name: “gemini”)
    - gemini-2.5-pro
- For Claude models (provider-name: “claude”)
    - claude-4-sonnet-20250514
    - claude-sonnet-4-5-20250929
    - claude-haiku-4-5-20251001
- For OpenAI models (provider-name: “openai”)
    - gpt-5
    - gpt-5-mini

## API Rate Limit
To ensure the stability of public API, we implement rate limiting. Exceeding these limits will result in an `429 Too Many Requests status` code.

### 1. Eval job creation
Endpoint: `POST /open-eval-api/v1/eval`
| Limit Type | Rate | Time Window |
| :--- | :--- | :--- |
| Per **API Key** | 50 requests | Per hour |
| Per **API Key** | 100 requests | Per day |
| Per **IP Address** | 100 requests | Per day |

### 2. Polling job status
Endpoint: `GET /open-eval-api/v1/eval-records/{jobId}`

| Limit Type | Rate | Time Window |
| :--- | :--- | :--- |
| Per **API Key** | 60 requests | Per minute |
| Per **IP Address** | 60 requests | Per minute |

## Troubleshooting

### Common Issues

1. **LLM Name/API Key Required**: You must provide `--llm-name` and `--llm-api-key` (or set `LLM_API_KEY` in `.env`). You will use your own LLM credentials for evaluations.
2. **API Key Not Found**: Ensure your Open Game Eval API key is set in the `.env` file or passed via `--api-key`. See `.env.example` as an example.
3. **Permission Denied**: Verify your API key has proper scope (`studio-evaluation:create`).
4. **Timeout Errors**: Evaluations have a 10-minute timeout.
5. **File Not Found**: Check file paths and ensure evaluation files exist.
6. **SSL certificate verify failed**: Find the `Install Certificates.command` in finder and execute it. ([See details and other solutions](https://stackoverflow.com/questions/52805115/certificate-verify-failed-unable-to-get-local-issuer-certificate))
7. **No output from Lua**: If the eval failed with error `Error occurred, no output from Lua`, it is caused by incorrect LLM info being passed in. Please double-check `llm-api-key` is correct, and `llm-model-version` is one of the available versions listed. 

## API Reference

### Base URL
```
https://apis.roblox.com/open-eval-api/v1
```

### Endpoints

#### Submit Evaluation with Custom LLM Configuration
```bash
curl -X POST 'https://apis.roblox.com/open-eval-api/v1/eval' \
  --header 'Content-Type: application/json' \
  --header "x-api-key: $OPEN_GAME_EVAL_API_KEY" \
  --data "$(jq -n --rawfile script Evals/001_make_cars_faster.lua '{
    name: "make_cars_faster",
    description: "Evaluation on making cars faster",
    input_script: $script,
    custom_llm_info: {
      name: "provider-name", // ← Provider only, claude | gemini | openai
      api_key: "your-provider-api-key",
      model_version: "model-version", // ← see example model versions below
      url: "dummy_url_not_effective",
    }
  }')"
```

#### Check Status
```bash
curl 'https://apis.roblox.com/open-eval-api/v1/eval-records/{job_id}' \
  --header "x-api-key: $OPEN_GAME_EVAL_API_KEY"
```

### Job Status Values
- `QUEUED`: Job is waiting to be processed
- `PENDING`: Job is being processed  
- `COMPLETED`: Job finished successfully
- `FAILED`: Job failed

## Evaluation Structure

Each evaluation file follows this structure:

```lua
local eval: BaseEval = {
    scenario_name = "001_make_cars_faster", -- Name of the eval
    prompt = {
        {
            {
                role = "user",
                content = "Make the cars of this game 2x faster", -- User prompt
            }
        }
    },
    place = "racing.rbxl", --Name of placefile used. Currently only supports Roblox templates.
}

-- Setup necessary changes to the placefile before evaluation
eval.setup = function()
    -- Create necessary set up to placefile, including selection
end

-- Reference function (optional, used when running evals with use-reference-mode)
eval.reference = function()
    -- Expected behavior implementation. They are intentionally left blank in this set for the purpose of evaluation.
end

-- Validation function
eval.check_scene = function()
    -- Checks for edit mode
end

eval.check_game = function()
    -- Checks for play mode
end

return eval
```

## Contributing

This repository contains open-source evaluation scripts. To contribute:

1. Fork the repository
2. Create evaluation scripts following the established format
3. Test your evaluations thoroughly
4. Submit a pull request with clear documentation

## License

This project is part of Roblox's open-source initiative. Please refer to the repository's license file for details.

## Support
- Contact the Roblox team for API access and permissions
