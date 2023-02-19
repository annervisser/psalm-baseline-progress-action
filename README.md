# Psalm baseline progress
A GitHub action that calculates the size of your psalm baseline.
Allowing you to track the progress of your baseline over time.

The score is the total number of occurrences of `<code></code>` blocks

## Usage

### Inputs
> **Note**: All inputs are optional and the defaults should work in most cases 

| Input            | Default                                   | Description                                   |
|------------------|-------------------------------------------|-----------------------------------------------|
| base_ref         | ${{ github.event.pull_request.base.sha }} | git ref to use for calculating the base_score |
| head_ref         | 'HEAD'                                    | git ref to use for calculating the head_score |
| path_to_baseline | './psalm-baseline.xml'                    | Path to the baseline file                     |


### Outputs
| Output     | Description                                                 |
|------------|-------------------------------------------------------------|
| base_score | Baseline score at base_ref (see #Inputs)                    |
| head_score | Baseline score at head_ref (see #Inputs)                    |
| score_diff | Difference between the two scores (head_score - base_score) |

## Examples

### Comment on Pull requests
```yaml
on:
  pull_request:
jobs:
  test-action:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write # Needed to post a comment on a pull request
    steps:
      - uses: actions/checkout@v3

      - id: baseline-scores
        uses: annervisser/psalm-baseline-progress-action@v1

      - uses: thollander/actions-comment-pull-request@v2
        if: steps.baseline-scores.score_diff != 0 # Only comment if the score has changed
        with:
          message: |
            psalm baseline score changed: **${{ steps.baseline-scores.outputs.base_score }}** -> **${{ steps.baseline-scores.outputs.head_score }}**
          comment_tag: 'psalm_baseline_score_comment' # This allows the comment to be updated when the pull request changes
```

### Fail pull request check if baseline has grown
```yaml
on:
  pull_request:
jobs:
  test-action:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - id: baseline-scores
        uses: annervisser/psalm-baseline-progress-action@v1

      - if: steps.baseline-scores.score_diff > 0
        run: |
          echo ::error::Baseline has grown by ${{ steps.baseline-scores.score_diff }}
          exit 1
```
