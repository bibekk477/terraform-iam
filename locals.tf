locals{
  users = csvdecode(file("users.csv"))# create a list of maps from the CSV file
}