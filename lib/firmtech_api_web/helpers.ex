defmodule FirmtechApiWeb.Helpers do
  require Protocol

  Protocol.derive(Jason.Encoder, Flop.Meta,
    only: [
      :current_offset,
      :current_page,
      :end_cursor,
      :has_next_page?,
      :has_previous_page?,
      :next_offset,
      :next_page,
      :page_size,
      :previous_offset,
      :previous_page,
      :start_cursor,
      :total_count,
      :total_pages
    ]
  )
end
