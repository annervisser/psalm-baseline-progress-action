# Psalm baseline progress
A GitHub action that calculates the size of your psalm baseline.
Allowing you to track the progress of your baseline over time.

The score is the total number of occurrences of `<code></code>` blocks in the baseline

![image](https://github.com/user-attachments/assets/1630daf6-6dc3-4787-b183-09ffd23e4055)

---

<!-- TOC -->
* [Usage](#usage)
  * [Inputs](#inputs)
  * [Outputs](#outputs)
  * [Custom file filters](#custom-file-filters)
  * [Templates](#templates)
* [Examples](#examples)
  * [Comment on pull requests](#comment-on-pull-requests)
  * [Fail pull request check if baseline has grown](#fail-pull-request-check-if-baseline-has-grown)
<!-- TOC -->

## Usage

### Inputs
> **Note**: All inputs are optional and the defaults should work in most cases 

| Input                | Default                                     | Description                                                                                                                                                       |
|----------------------|---------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| base_ref             | `${{ github.event.pull_request.base.sha }}` | git ref to use for calculating the base_score                                                                                                                     |
| head_ref             | `'HEAD'`                                    | git ref to use for calculating the head_score                                                                                                                     |
| path_to_baseline     | `'./psalm-baseline.xml'`                    | Path to the baseline file                                                                                                                                         |
| file_xpath_condition | `'not(starts-with(@src, "test"))'`          | A custom xpath condition to filter specific file entries. <br/>Default to excluding paths that start with "test"<br/> Set to an empty string to include all files |
| template_decreased   | See [Templates](#Templates)                 | Template to use when the baseline has decreased (See [Templates](#Templates))                                                                                     |
| template_increased   | See [Templates](#Templates)                 | Template to use when the baseline has grown (See [Templates](#Templates))                                                                                         |
| template_no_change   | See [Templates](#Templates)                 | Template to use when the baseline score hasn't changed (See [Templates](#Templates))                                                                              |

### Outputs
| Output            | Description                                                                  |
|-------------------|------------------------------------------------------------------------------|
| base_score        | Baseline score at base_ref                                                   |
| head_score        | Baseline score at head_ref                                                   |
| score_diff        | Difference between the two scores (head_score - base_score)                  |
| score_diff_string | Same a `score_diff`, with a `+` prepended for positive numbers               |
| output_message    | Parsed output based on the `template_*` inputs (See [Templates](#Templates)) |

### Custom file filters

You can set `file_xpath_condition` to include or exclude specific files.
The value should be a valid XPath 1.0 expression that can be applied to `<file/>` entries.
By default, files whose path starts with `test` are excluded.

For a list of available functions, see [MDN](https://developer.mozilla.org/en-US/docs/Web/XML/XPath/Reference/Functions)

#### Example filters

| `file_xpath_condition`                                          | Description                                          |
|-----------------------------------------------------------------|------------------------------------------------------|
| `not(starts-with(@src, 'tests/'))`                              | Exclude files in the `tests` directory               |
| `not(starts-with(@src, 'tests/') or starts-with(@src, 'bin/'))` | Exclude files in the `tests` and `bin` directories   |
| `contains(@src, '/domain/')`                                    | Include only files contains `/domain/` in their path |

### Templates
The template_* inputs allow you to specify different templates for when the score increases/decreases/remains the same.

These templates are parsed by `envsubst`, with valid substitutions being: `$BASE_SCORE`, `$HEAD_SCORE`, `$SCORE_DIFF` & `$SCORE_DIFF_STRING`

The relevant template is parsed and output to `output_message` for you to use.

#### Customising the templates
```yaml
- id: baseline-scores
  uses: annervisser/psalm-baseline-progress-action@v1
  with:
    template_decreased: 'Baseline decreased! from $BASE_SCORE to $HEAD_SCORE'
    template_increased: |
      The baseline has increased!
      Old score: $BASE_SCORE
      New score: $HEAD_SCORE
      Difference: $SCORE_DIFF_STRING
    template_no_change: 'Nothing''s changed!'
```

#### The default templates look like this:

- `🍀 Psalm baseline has decreased: **$BASE_SCORE** → **$HEAD_SCORE** _(**${SCORE_DIFF}**)_` \
🍀 Psalm baseline has decreased: **500** → **490** _(**-10**)_

- `📛 Psalm baseline has increased: **$BASE_SCORE** → **$HEAD_SCORE** _(**+${SCORE_DIFF}**)_` \
📛 Psalm baseline has increased: **500** → **510** _(+**10**)_

- `Psalm baseline score remained the same: **$HEAD_SCORE**` \
Psalm baseline score remained the same: **500**

## Examples

### Comment on pull requests
See [Templates](#Templates) for customizing the `output_message`
```yaml
on:
  pull_request:
jobs:
  comment-psalm-baseline-progress:
    runs-on: ubuntu-latest
    permissions:
      contents: read # Default permission when no others are specified, needed for actions/checkout
      pull-requests: write # Needed to post a comment on a pull request
    steps:
      - uses: actions/checkout@v4

      - id: baseline-scores
        uses: annervisser/psalm-baseline-progress-action@v1

      - uses: thollander/actions-comment-pull-request@v3
        with:
          message: ${{ steps.psalm-baseline-progress-action.outputs.output_message }}
          comment-tag: 'psalm_baseline_score_comment' # Add marker so existing comment can be updated
          create-if-not-exists: ${{ steps.psalm-baseline-progress-action.outputs.score_diff != 0 }} # Only create comment when baseline score changed, but always update existing comment
          # github-token: <a GitHub PAT> # Only needed to comment on pull requests coming from forks
```

### Fail pull request check if baseline has grown
```yaml
on:
  pull_request:
jobs:
  reject-psalm-baseline-increases:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - id: baseline-scores
        uses: annervisser/psalm-baseline-progress-action@v1

      - if: steps.baseline-scores.outputs.score_diff > 0
        run: |
          echo ::error::Baseline has grown by ${{ steps.baseline-scores.score_diff }}
          exit 1
```
