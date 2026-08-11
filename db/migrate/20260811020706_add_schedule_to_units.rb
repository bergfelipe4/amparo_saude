class AddScheduleToUnits < ActiveRecord::Migration[8.1]
  def change
    # Minutos desde a meia-noite (ex: 480 = 08:00), em vez de coluna :time —
    # colunas :time do Postgres levam o Rails a aplicar conversão de fuso
    # horário (time_zone_aware_attributes) na leitura, deslocando o horário
    # (08:00 virava 06:00 nos testes). Como isso é só "horário da agenda", não
    # tem nenhuma semântica de fuso pra preservar — inteiro evita o problema.
    #
    # working_days usa a convenção de Date#wday do Ruby: 0 = domingo .. 6 = sábado
    add_column :units, :opens_at_minutes, :integer, default: 480, null: false  # 08:00
    add_column :units, :closes_at_minutes, :integer, default: 1080, null: false # 18:00
    add_column :units, :working_days, :integer, array: true, default: [1, 2, 3, 4, 5], null: false
  end
end
