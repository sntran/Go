# The progress is in SQLite (tmp/go_test.db). The tests start with no
# progress, because the names of the test players repeat in each run.
Go.Repo.query!("DELETE FROM progress")
Go.Repo.query!("DELETE FROM attempts")

ExUnit.start()
