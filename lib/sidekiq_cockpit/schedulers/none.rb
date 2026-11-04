module SidekiqCockpit
  module Schedulers
    # Без планировщика: расписаний нет, все задачи — «по событиям».
    class None < Base
    end
  end
end
