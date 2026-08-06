require "prawn"
require "prawn/table"
require "rqrcode"
require "vips"

# Shared letterhead, signature block and QR verification stamp for official documents
# (encounter records, prescriptions). Subclasses implement #body.
class ClinicDocumentPdf
  include Prawn::View

  INK = "16211C"
  MUTED = "6A6A63"
  ACCENT = "0B5D52"
  LINE = "DCDCD6"

  def initialize
    @document = Prawn::Document.new(page_size: "A4", margin: [50, 50, 60, 50])
    document.font "Helvetica"
    document.fill_color INK
  end

  def document
    @document
  end

  def render
    letterhead
    body
    signature_and_verification
    document.render
  end

  private

  def unit
    raise NotImplementedError
  end

  def title
    raise NotImplementedError
  end

  def body
    raise NotImplementedError
  end

  def professional
    raise NotImplementedError
  end

  def verification_seed
    raise NotImplementedError
  end

  def letterhead
    document.fill_color INK
    document.font "Helvetica", style: :bold, size: 15
    document.text "Amparo Saúde"
    document.font "Helvetica", size: 8
    document.fill_color MUTED
    document.text "Unidade #{unit.name} — #{unit.address}\n#{unit.phone}"
    document.fill_color INK
    document.move_down 4
    document.stroke_color LINE
    document.stroke_horizontal_rule
    document.move_down 14
    document.font "Helvetica", style: :bold, size: 12
    document.text title.upcase, align: :center, character_spacing: 1
    document.move_down 12
    document.font "Helvetica", size: 9
  end

  def field_row(label, value)
    return if value.blank?
    document.font "Helvetica", style: :bold, size: 8.5
    document.fill_color MUTED
    document.text label.upcase, character_spacing: 0.5
    document.font "Helvetica", size: 10
    document.fill_color INK
    document.text value.to_s
    document.move_down 8
  end

  def section_title(text)
    document.move_down 6
    document.font "Helvetica", style: :bold, size: 9.5
    document.fill_color ACCENT
    document.text text.upcase, character_spacing: 0.5
    document.fill_color INK
    document.font "Helvetica", size: 10
    document.move_down 3
  end

  def verification_token
    Digest::SHA256.hexdigest(verification_seed.to_s)[0, 16]
  end

  # Uploaded signatures can come in formats Prawn's PNG parser rejects (e.g. Adam7
  # interlaced PNGs). Round-tripping through libvips re-encodes to a plain PNG Prawn
  # can always read. We also trim the surrounding whitespace/transparent margin so the
  # ink sits right against the signature line instead of floating in the middle of
  # whatever canvas size the original file happened to have. Never let a bad
  # signature file break the whole document.
  def safe_signature_png
    signature = professional.user&.signature
    return nil unless signature&.attached?

    image = Vips::Image.new_from_buffer(signature.download, "")
    trim_signature_whitespace(image).write_to_buffer(".png")
  rescue StandardError => e
    Rails.logger.warn("ClinicDocumentPdf: falha ao processar assinatura (#{e.class}: #{e.message})")
    nil
  end

  def trim_signature_whitespace(image)
    left, top, width, height = image.flatten(background: [255, 255, 255]).find_trim(threshold: 12, background: [255, 255, 255])
    return image if width <= 0 || height <= 0
    image.crop(left, top, width, height)
  rescue StandardError
    image
  end

  def signature_and_verification
    document.move_down 26
    y = document.cursor

    if (png = safe_signature_png)
      document.image StringIO.new(png), at: [50, y + 34], fit: [170, 32]
    end

    document.stroke_color INK
    document.line_width 0.6

    sig_width = 300
    document.stroke_line [50, y], [50 + sig_width, y]
    document.move_down 4
    document.font "Helvetica", style: :bold, size: 9.5
    document.text professional.name
    document.font "Helvetica", size: 8.5
    document.fill_color MUTED
    document.text professional.crm

    qr_png = RQRCode::QRCode.new("https://amparosaude.com.br/verificar/#{verification_token}").as_png(size: 300)
    document.image StringIO.new(qr_png.to_s), at: [document.bounds.width - 60, y + 8], width: 60
    document.fill_color MUTED
    document.font "Helvetica", size: 6
    document.draw_text "Verificar em amparosaude.com.br/verificar", at: [document.bounds.width - 60, y - 46], size: 6
    document.draw_text verification_token, at: [document.bounds.width - 60, y - 56], size: 6

    document.fill_color MUTED
    document.font "Helvetica", size: 7
    document.number_pages "Página <page> de <total> — documento gerado eletronicamente em #{I18n.l(Time.current, format: :short)}",
                           at: [document.bounds.left, 0], align: :center, size: 7
  end
end
