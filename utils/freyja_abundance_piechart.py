# Import required packages
import pandas as pd
import re
import os
import glob
import matplotlib.pyplot as plt

# Function to prepare lineage dictionary
def prepLineageDict(agg_d0):
    # Split the 'lineages' and 'abundances' fields by spaces
    agg_d0.loc[:, 'lineages'] = agg_d0['lineages'].apply(lambda x: re.sub(' +', ' ', x).split(' ')).copy()
    agg_d0.loc[:, 'abundances'] = agg_d0['abundances'].apply(lambda x: re.sub(' +', ' ', x).split(' ')).copy()

    # Create 'linDict' column with mapped lineages and abundances values
    agg_d0.loc[:, 'linDict'] = [
        {lin: float(abund) for lin, abund in zip(agg_d0.loc[samp, 'lineages'], agg_d0.loc[samp, 'abundances'])}
        for samp in agg_d0.index
    ]

    return agg_d0  # Return the updated DataFrame

def makePieCharts_simple(agg_df, lineages, outputFnBase, config, lineage_info=None):
    # Prepare the lineage dictionary if lineages is given
    if lineages:
        queryType = 'linDict'
        config = config.get('Lineages')
        agg_df = prepLineageDict(agg_df, config=config, lineage_info=lineage_info)
    else:
        queryType = 'summarized'
        config = config.get('VOC')
        agg_df = prepSummaryDict(agg_df)

    # Loop over all samples in the DataFrame
    for i, sampLabel in enumerate(agg_df.index):
        # Extract the lineage dictionary for the current sample
        dat = agg_df.loc[sampLabel, queryType]
        if isinstance(dat, list):
            loc = pd.Series(dat[0])
        else:
            loc = pd.Series(dat)

        # Create the pie chart
        fig, ax = plt.subplots()
        ax.pie(loc, labels=loc.index, autopct='%1.1f%%', startangle=90)
        ax.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.

        # Use the sample name in the filename and the title
        plt.title(sampLabel)
        plt.savefig(outputFnBase + sampLabel + '.png')
        plt.close()

import matplotlib.pyplot as plt

def makePieCharts_simple(agg_df, lineages, outputFnBase, config, lineage_info=None):
    # Prepare the lineage dictionary if lineages is given
    if lineages:
        queryType = 'linDict'
        config = config.get('Lineages')
        agg_df = prepLineageDict(agg_df, config=config, lineage_info=lineage_info)
    else:
        queryType = 'summarized'
        config = config.get('VOC')
        agg_df = prepSummaryDict(agg_df)

    # Default color scheme
    default_cmap_dict = {
        24: px.colors.qualitative.Dark24
    }

    # Loop over all samples in the DataFrame
    for i, sampLabel in enumerate(agg_df.index):
        # Extract the lineage dictionary for the current sample
        dat = agg_df.loc[sampLabel, queryType]
        if isinstance(dat, list):
            loc = pd.Series(dat[0])
        else:
            loc = pd.Series(dat)

        # Create color scheme for the pie chart
        cmap_dict = get_color_scheme(loc.to_frame().T, default_cmap_dict, config)

        # Map colors to labels
        pie_colors = [cmap_dict[label] for label in loc.index]

        # Create the pie chart
        fig, ax = plt.subplots()
        ax.pie(loc, labels=loc.index, colors=pie_colors, autopct='%1.1f%%', startangle=90)
        ax.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.

        # Use the sample name in the filename and the title
        plt.title(f'{sampLabel}_Variant Prevalence')
        plt.savefig(outputFnBase + sampLabel + '_Variant Prevalence.png')
        plt.close()

# 3rd Iteration
def makePieCharts_simple(agg_df, lineages, outputFn, config, lineage_info):
    if lineages:
        queryType = 'linDict'
        config = config.get('Lineages')
        agg_df = prepLineageDict(agg_df, config=config,
                                 lineage_info=lineage_info)

    else:
        queryType = 'summarized'
        config = config.get('VOC')
        agg_df = prepSummaryDict(agg_df)

    # Make piechart for each sample in the aggregated dataset
    for i, sampLabel in enumerate(agg_df.index):
        plt.figure(figsize=(10, 8))
        dat = agg_df.loc[sampLabel, queryType]
        if isinstance(dat, list):
            dat = dat[0]
        # Pie chart
        labels = list(dat.keys())
        sizes = list(dat.values())

        default_colors = px.colors.qualitative.Dark24
        color_scheme = get_color_scheme(pd.DataFrame([dat]), {len(default_colors): default_colors}, config)
        colors = [color_scheme[label] for label in labels]
        
        plt.pie(sizes, labels=labels, autopct='%1.1f%%', colors=colors)
        plt.title(f"{sampLabel}_Variant Prevalence", fontdict={'fontsize': 20})
        outputFn_base, _ = os.path.splitext(outputFn)
        plt.savefig(outputFn_base + f"_{sampLabel}_PieChart.png")
        plt.close()


# Gather all '*lineages_aggregate.tsv' files in the current directory
source_files = glob.glob('*lineages_aggregate.tsv')
for file in source_files:
    print(file)
    # Read the current file into a DataFrame
    df = pd.read_csv(file, sep="\t", index_col=0)
    # Create pie charts for each sample in the DataFrame
    makePieCharts_simple(df, 'lineages', 'freyja_sublin_pie_')


