module ApplicationHelper
  def share_button
    str = <<END
      <div id="share-button-top" class="share-button share-button-top"></div>
      <script type="text/javascript">new Share(".share-button", { ui: { flyout: "bottom left", button_background: "rgb(128,160,160)", button_color: "rgb(0,39,39)" } });</script>
END
    str.html_safe
  end
end
