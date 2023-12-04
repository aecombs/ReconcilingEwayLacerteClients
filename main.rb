require 'csv'

lacerte_clients = CSV.parse(File.read('./lacerte_clients.csv'), headers: true).map(&:to_h)
eway_clients = CSV.parse(File.read('./eway_clients.csv'), headers: true).map(&:to_h)
preparers = {
  '0' => '',
  '1' => 'Andy Andrikopoulos',
  '2' => 'Tim Chiochios',
  '3' => '',
  '4' => 'Kathryn Kauffman',
  '5' => '',
  '6' => 'Caitlin White',
  '7' => 'Alganesh Gerezgiher',
  '8' => 'Kathy McGinnis',
  '9' => '',
  '11' => 'Dennis Daly',
  '12' => 'Merry C Davis'
}

eway = []
eway_clients.each do |client|
  # skip if the account_name is nil
  next unless client['Account Name'].is_a?(String)

  account_name = client['Account Name'].upcase
  names = account_name.split(',')
  last_name = names[0].strip
  first_names = names[1]
  first_names = first_names.strip if first_names.is_a?(String)
  preparer = client['Preparer'].to_s.strip

  eway.push([last_name, first_names, preparer])
end

lacerte = {}
clients_to_reconcile = {}
lacerte_clients.each do |client|
  # skip if the account_name is nil
  next unless client['Account Name'].is_a?(String)

  account_name = client['Account Name'].upcase
  names = account_name.split(',')
  last_name = names[0].strip
  first_names = names[1]
  first_names = first_names.strip if first_names.is_a?(String)

  # grab the corresponding preparer & staff preparer string
  preparer = ''
  preparer_int = client['Preparer'].to_s
  preparer = preparers[preparer_int]
  staff = ''
  staff_int = client['Staff Preparer'].to_s
  staff = preparers[staff_int]

  lacerte[account_name] = [last_name, first_names, preparer, staff]
  clients_to_reconcile[account_name] = preparer
end

partial_matches = {}
reconciled_clients = {}
nonmatching_preparers = {}
# check first if the last names match, then check the first four letters of first name
lacerte.each do |lacerte_account_name, name_array|
  lacerte_last_name = name_array[0]
  lacerte_first_name = name_array[1]
  lacerte_preparer = name_array[2]
  lacerte_staff = name_array[3]

  eway.each do |eway_array|
    eway_last_name = eway_array[0]
    eway_first_name = eway_array[1]
    eway_preparer = eway_array[2]

    # check last names
    next unless eway_last_name == lacerte_last_name

    matching_chars = ''
    matches = false

    # check first four letters of first name
    i = 0
    while i < eway_first_name.length
      matching_chars += lacerte_first_name[i] if eway_first_name[i] == lacerte_first_name[i]
      i += 1
    end

    # considering it matching if at least the first four letters match
    matches = true if matching_chars.strip.length >= 4

    if matches
      # add to hash for reconciled_clients.csv
      reconciled_clients[lacerte_account_name] = clients_to_reconcile[lacerte_account_name]

      # remove from hash for clients_to_reconcile.csv
      clients_to_reconcile.delete(lacerte_account_name)

      # if preparers don't match, add to hash for nonmatching_preparers.csv
      if !(lacerte_preparer == eway_preparer) && !(lacerte_staff == eway_preparer)
        nonmatching_preparers[lacerte_account_name] =
          "#{lacerte_preparer},#{lacerte_staff},#{eway_preparer}"
      end
    end

    # if the conditions are not met for fully "matching", update the hash for matching last names but not first names.
    unless matches
      full_name = "#{eway_last_name}, #{eway_first_name}"
      partial_matches[lacerte_account_name] = full_name
    end
  end
end

CSV.open('./clients_to_reconcile.csv', 'wb') do |csv|
  csv << ['Account Name', 'Preparer']

  clients_to_reconcile.each do |client|
    csv << client
  end
end

CSV.open('./reconciled_clients.csv', 'wb') do |csv|
  csv << ['Account Name', 'Preparer']

  reconciled_clients.each do |client|
    csv << client
  end
end

CSV.open('./partial_matches.csv', 'wb') do |csv|
  csv << ['Lacerte Account Name', 'eWay Account Name']

  partial_matches.each do |client|
    csv << client
  end
end

CSV.open('./nonmatching_preparers.csv', 'wb') do |csv|
  csv << ['Account Name', 'Lacerte Preparer', 'Lacerte Staff Preparer', 'eWay Preparer']

  nonmatching_preparers.each do |client|
    csv << client
  end
end
