'''
Check the order and number of fields in .pp file and their values' ranges.
'''

import cf

# A UM output .pp file or list of files.
# Put the file path to your .pp or fieldsfile file(s) here, e.g.
um_files = ['atmosa.da19880903_00', 'cy731a.pl20160823.pp']

for um_file in um_files:
  print(f'\n{um_file}')
  
  # Open it in CF Python.
  print('Loading data.')
  day = cf.read(um_file)

  for field in day:
    # Long name is more informative than identity.
    try:
      name = field.long_name
    # Sometimes a field has no long name.
    except:
      name = field.identity()
    print(f'{name} ranges from {field.min()} to {field.max()}')

  print(f'There are {len(day)} fields in the dataset.')
 
