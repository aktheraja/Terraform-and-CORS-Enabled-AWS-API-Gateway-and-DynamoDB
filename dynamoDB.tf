resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "Cloud_Infrastructure"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "UserId"


attribute {
    name = "UserId"
    type = "S"
  }

//  ttl {
//    attribute_name = "TimeToExist"
//    enabled        = false
//  }

  tags = {
    Name        = "dynamodb-table-Infrastructure"
    Environment = "production"
  }
}