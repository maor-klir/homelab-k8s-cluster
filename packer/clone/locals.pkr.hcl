locals {
  buildtime = regex_replace(timestamp(), "[- TZ:]", "")
}