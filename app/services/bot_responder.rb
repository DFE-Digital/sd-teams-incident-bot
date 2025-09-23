class BotResponder
  # Build a simple text reply activity
  def self.text_reply(request_activity, text)
    {
      type: "message",
      from: request_activity["recipient"],
      recipient: request_activity["from"],
      replyToId: request_activity["id"],
      serviceUrl: request_activity["serviceUrl"],
      channelId: request_activity["channelId"],
      conversation: request_activity["conversation"],
      text: text
    }
  end

  # Build an Adaptive Card reply
  def self.card_reply(request_activity, card_json)
    {
      type: "message",
      from: request_activity["recipient"],
      recipient: request_activity["from"],
      replyToId: request_activity["id"],
      serviceUrl: request_activity["serviceUrl"],
      channelId: request_activity["channelId"],
      conversation: request_activity["conversation"],
      attachments: [{
        contentType: "application/vnd.microsoft.card.adaptive",
        content: card_json
      }]
    }
  end
end