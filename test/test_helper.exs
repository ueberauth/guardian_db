{:ok, _pid} = Guardian.DB.TestSupport.Repo.start_link()
ExUnit.start()
Mox.defmock(Guardian.DB.MockAdapter, for: Guardian.DB.Adapter)
