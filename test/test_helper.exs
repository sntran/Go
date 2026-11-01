# The progress is in SQLite (tmp/go_test.db). The tests start with no
# progress, because the names of the test players repeat in each run.
Go.Repo.query!("DELETE FROM progress")
Go.Repo.query!("DELETE FROM attempts")
Go.Repo.query!("DELETE FROM library_versions")
Go.Repo.query!("DELETE FROM transfer_codes")
Go.Repo.query!("DELETE FROM transfer_tries")
Go.Library.Seen.reload()

ExUnit.start()
