# MailPacket

Minimal Flynn-enabled wrapper around libetpan to perform basic mail functionality:

- connect
- search
- download headers
- download eml
- append (save an eml to a folder, ie Sent or Drafts)
- send (via SMTP)
- compose (build rfc5322 eml)
