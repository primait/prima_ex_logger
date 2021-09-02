~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
  default_release: :default,
  default_environment: Mix.env()

environment :dev do
  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :"M5aD&@DE=[2!ilMGv8wmj:oFgJXM(W5*tW}rLx/oRA?c:CmiE;}bS$!MF])d5ia`")
end

environment :prod do
  set(include_erts: true)
  set(include_src: false)
  set(cookie: :"mL_6XaI5VabkE4fp1DG!1_0KvN`jWXsDK35)?N{Sw_d6w%3ARQKz=Q4&7S>[jh6(")
  set(vm_args: "rel/vm.args")
end

release :test_app do
  set(version: current_version(:test_app))

  set(
    applications: [
      :runtime_tools,
      :distillery
    ]
  )
end
