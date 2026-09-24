module BookingsHelper
  def qr_code_svg(token, size: 180)
    qr = RQRCode::QRCode.new(token)
    raw qr.as_svg(
      color: "e8112d",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true,
      viewbox: true,
      svg_attributes: { width: size, height: size, role: "img", "aria-label": "QR-Code des Tickets" }
    )
  end

  def booking_reference(booking)
    "KA-#{booking.qr_code_token.delete('-')[0, 8].upcase}"
  end
end
