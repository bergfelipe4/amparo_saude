module Whatsapp
  # Traduz o status bruto do WPPConnect pra um estado + label em português.
  # Confirmado lendo o código de fato instalado (@wppconnect/server, via
  # server-cli) em util/createSessionUtil.js — o pacote usa seu próprio
  # conjunto de status (INITIALIZING/QRCODE/PHONECODE/CONNECTED/CLOSED),
  # diferente do enum StatusFind da lib wppconnect subjacente. Mantendo os
  # valores do StatusFind também, por segurança, caso outra versão os use.
  class ConnectionStatus
    STATUS_MAP = {
      "INITIALIZING" => { state: "iniciando", label: "Preparando conexão…" },
      "QRCODE" => { state: "aguardando_qr", label: "Escaneie o QR Code no WhatsApp do celular" },
      "PHONECODE" => { state: "aguardando_qr", label: "Use o código de pareamento no WhatsApp do celular" },
      "CONNECTED" => { state: "conectado", label: "Conectado" },
      "CLOSED" => { state: "nao_iniciado", label: "Não conectado" },
      "notLogged" => { state: "aguardando_qr", label: "Escaneie o QR Code no WhatsApp do celular" },
      "qrReadSuccess" => { state: "conectando", label: "QR Code lido! Conectando…" },
      "isLogged" => { state: "conectado", label: "Conectado" },
      "inChat" => { state: "conectado", label: "Conectado" },
      "qrReadError" => { state: "erro", label: "Falha ao ler o QR Code. Tente de novo." },
      "qrReadFail" => { state: "erro", label: "A leitura do QR Code falhou. Tente de novo." },
      "phoneNotConnected" => { state: "erro", label: "Não foi possível conectar ao celular." },
      "disconnectedMobile" => { state: "desconectado", label: "Desconectado pelo celular." },
      "serverClose" => { state: "desconectado", label: "Conexão encerrada." },
      "browserClose" => { state: "desconectado", label: "Sessão encerrada." },
      "autocloseCalled" => { state: "expirado", label: "Tempo esgotado — gere um novo QR Code." }
    }.freeze

    DEFAULT = { state: "nao_iniciado", label: "Não conectado" }.freeze
    CONNECTED_STATES = %w[conectado].freeze

    def self.call(...) = new(...).call

    def initialize(raw_status)
      @raw_status = raw_status
    end

    def call
      mapped = STATUS_MAP.fetch(@raw_status, DEFAULT)
      mapped.merge(connected: CONNECTED_STATES.include?(mapped[:state]))
    end
  end
end
