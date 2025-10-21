# Simple Work Stream Example
#
# This demonstrates how Nickel contracts can validate work stream schemas
# with runtime verification.

{
  work_stream_branch
    | doc "The Git branch name for this work stream"
    | String
    = "feature/example-feature",

  status
    | doc "Current status of the work stream"
    | [| 'planning, 'in_progress, 'completed |]
    = 'in_progress,

  stages
    | doc "Development stages with tasks"
    | Array {
        name | String,
        status | [| 'pending, 'in_progress, 'completed |],
        tasks | Array {
          content | String,
          status | [| 'pending, 'in_progress, 'completed |],

          # TDD tracking (optional)
          tdd_phase
            | [| 'red, 'green, 'refactor, 'none |]
            | default
            = 'none,

          # Cryptographic verification (optional)
          commits
            | {
                red_commit | String | optional,
                green_commit | String | optional,
                refactor_commits | Array String | default = [],
              }
            | default
            = {},
        },
      }
    = [
        {
          name = "Requirements & Design",
          status = 'completed,
          tasks = [
            {
              content = "Define feature requirements",
              status = 'completed,
              tdd_phase = 'none,
            },
            {
              content = "Design Nickel schema",
              status = 'completed,
              tdd_phase = 'none,
            },
          ],
        },
        {
          name = "Implementation",
          status = 'in_progress,
          tasks = [
            {
              content = "Write test for validation function",
              status = 'completed,
              tdd_phase = 'red,
              commits = {
                red_commit = "abc123",
              },
            },
            {
              content = "Implement validation function",
              status = 'in_progress,
              tdd_phase = 'green,
              commits = {
                red_commit = "abc123",
                green_commit = "def456",
              },
            },
          ],
        },
      ],

  # Cryptographic verification policy
  verification_policy = {
    require_signatures
      | doc "All commits must be cryptographically signed"
      | Boolean
      = true,

    status_pr_before_code_pr
      | doc "Status PR must precede code PR"
      | Boolean
      = true,

    tdd_required
      | doc "TDD workflow required for code tasks"
      | Boolean
      = false,  # Optional for now
  },
}
