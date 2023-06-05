import re
import pandas as pd
import os

def prepLineageDict(agg_d0, thresh=0.001, config=None, lineage_info=None):
    agg_d0.loc[:, 'lineages'] = agg_d0['lineages'].apply(lambda x:
                                                         re.sub(' +', ' ', x)
                                                           .split(' ')).copy()
    agg_d0.loc[:, 'abundances'] = agg_d0['abundances'].apply(lambda x:
                                                            re.sub(' +', ' ', x)
                                                              .split(' ')).copy()
    # print([float(abund) for abund in agg_d0.iloc[0].loc['abundances']])
    #Create 'linDict' column with mapped lineages and abundances values
    agg_d0.loc[:, 'linDict'] = [{lin: float(abund) for lin, abund in
                                zip(agg_d0.loc[samp, 'lineages'],
                                    agg_d0.loc[samp, 'abundances'])}
                                for samp in agg_d0.index]

   
    return agg_d0

def expand_data(processed_data):
    expanded_data = []

    for index, row in processed_data.iterrows():
        sample_id = row['sample_id']
        # summarized = row['summarized']
    
        # Extract the summarized lineage value
        # summarized_lineage = re.search(r"(\w+)", summarized)
        #if summarized_lineage:
        #    summarized_lineage_value = summarized_lineage.group(1)
        #else:
        #    summarized_lineage_value = None

        linDict = row['linDict']

        for lineage, abundance in linDict.items():
            expanded_data.append({
                'sample_id': sample_id,
                'lineage': lineage,
                'abundance': abundance,
                #'summarized_lineage': summarized_lineage_value
            })

    return pd.DataFrame(expanded_data)


#def get_parent_lineage(lineage, lineage_mapping):
 #   for parent_lineage, prefixes in lineage_mapping.items():
 #       if any(lineage.startswith(prefix) for prefix in prefixes):
  #          return parent_lineage
  #  return 'NA'

def get_parent_lineage(lineage, lineage_mapping):
    if lineage.startswith("X"):
        return "Recombinant"
        
    for parent_lineage_dict in lineage_mapping:
        parent_lineage = parent_lineage_dict["name"]
        prefixes = parent_lineage_dict["prefixes"]
        if any(re.match(f"^{prefix}(\\.|$)", lineage) for prefix in prefixes):
            return parent_lineage

    return 'NA'

def custom_parent(aliasor, name):
    uncompressed = aliasor.uncompress(name)
    #print(f"Uncompressed: {uncompressed}")
    name_split = uncompressed.split(".")
    if len(name_split) <= 3:
       return uncompressed
    parent_lineage = ".".join(name_split[:-1])
    #print(f"Parent Lineage: {parent_lineage}")
    compressed_parent = aliasor.compress(parent_lineage)
    #print(f"Compressed Parent: {compressed_parent}")
    return compressed_parent

def save_output(df, output_dir, output_file):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    output_path = os.path.join(output_dir, output_file)
    df.to_csv(output_path, index=False)
            

#def read_long_df(file):
 #   long_df = pd.read_csv(file, sep=',')
 #   long_df[['collection_date', 'msd_shrtnm']] = long_df['sample_id'].str.split('_', n=1, expand=True)
 #   long_df['collection_date'] = pd.to_datetime(long_df['collection_date'], format='%y%m%d')
 #  return long_df


#def merge_dataframes(df1, df2, on_column):
#    return pd.merge(df1, df2, on=on_column)


#def read_old_df(file):
#    old_df = pd.read_csv(file, sep=',')
#    old_df['collection_date'] = pd.to_datetime(old_df['collection_date'])
#    return old_df


#def concatenate_dataframes(df1, df2):
#    merged_df = pd.concat([df1, df2], ignore_index=True)
#   merged_df.reset_index(drop=True, inplace=True)
#    merged_df['idx_name'] = merged_df.index
#    return merged_df