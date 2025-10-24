defmodule TestProc do
  def spawn_link do
    :proc_lib.spawn_link(
      __MODULE__,
      :init,
      [
        self(),
        fn ->
          # Logger.metadata(foo: :bar)
          raise "oops"
        end
      ]
    )
  end

  def init(parent, fun) do
    Process.monitor(parent)
    Process.unlink(parent)
    # :proc_lib.init_ack(parent, {:ok, self()})

    receive do
      :go -> fun.()
    end
  end
end
