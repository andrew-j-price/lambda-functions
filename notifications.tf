resource "aws_sns_topic" "notifications_topic" {
  name = var.notifications_topic
}

resource "aws_sns_topic_subscription" "subscription_email" {
  count                  = length(var.sns_emails)
  topic_arn              = aws_sns_topic.notifications_topic.arn
  protocol               = "email"
  endpoint               = var.sns_emails[count.index]
  endpoint_auto_confirms = true
}

resource "aws_sns_topic_subscription" "subscription_webhook" {
  topic_arn              = aws_sns_topic.notifications_topic.arn
  protocol               = var.sns_webhook_protocol
  endpoint               = var.sns_webhook_url
  endpoint_auto_confirms = true
}
