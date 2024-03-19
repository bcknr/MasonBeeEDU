from pathlib import Path

import geopandas as gpd
import seaborn as sns

from shiny import App, Inputs, Outputs, Session, reactive, render, ui

sns.set_theme(style="white")
# df = pd.read_csv(Path(__file__).parent / "penguins.csv", na_values="NA")
baseServices = gpd.read_file(Path(__file__).parent / "data.gpkg", layer = 'baseServices')
baseServices['adj'] = baseServices['sum']

basePesticides = gpd.read_file(Path(__file__).parent / "data.gpkg", layer = 'basePesticides')
# basePesticides['kgPerArea'] = basePesticides['kgPerArea'].fillna(0.0)

cropLocations = gpd.read_file(Path(__file__).parent / "data.gpkg", layer = 'cropLocations')

species = ["Apples","Blueberries","Alfalfa","Corn"]


def make_value_box(crop):
    return ui.value_box(
        title=crop, value=ui.output_text(f"{crop}_count".lower()), theme="primary"
    )


app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.input_selectize(
            "richness",
            ui.h5("Bee Diversity"),
            ["high", "medium", "low"]
        ),
        ui.input_selectize(
            "ssp",
            ui.h5("Climate Change Scenario"),
            ["optimistic", "pessimistic"]
        ),
        ui.markdown(
            """
            An "optimistic scenario" reflects reduced greenhouse gas 
            emissions and more equitable socioeconomic factors.
            """
        ),   
        ui.input_slider(
            "pesticide",
            ui.h5("Pesticide Pressure"),
            0.01, 1.00, 0.25
        ),
                ui.markdown(
            """
            When pesticide pressure is higher more pesticides are 
            applied to the landscape. 
            """
        ), 
        ui.input_slider(
            "spring_vuln",
            ui.h5("Spring Bee Climate Vulnerability"),
            0.01, 1.00, 0.25
        ),
        ui.markdown(
            """
            Bees which are active in the spring are important for spring 
            blooming plants. Greater vulnerability means they are more likely
            to be negatively impacted by climate change.
            """
        ), 
        ui.input_slider(
            "buzz_vuln",
            ui.h5("Buzz Pollinating Bee Climate Vulnerability"),
            0.01, 1.00, 0.25
        ),
        ui.markdown(
            """
            Some plants must be pollinated by bees which can vibrate their 
            light muscles and shake the pollen out of tubular floral structures.
            """
        ), 
    ),
    ui.layout_columns(
        ui.card(
            ui.card_header("Pollination Services"),
            ui.output_plot("service_plot", width = "100%", height="800px"),
        ),
        ui.card(
            ui.card_header("Pollination Services by Crop"),
            ui.output_data_frame("service_curves"),
        ),
    ),
    ui.layout_columns(
        *[make_value_box(crop) for crop in species],
    ),
)


def server(input: Inputs, output: Outputs, session: Session):
    ####
    @reactive.calc
    def adjusted_services():
        # Lookup parameters
        n_spp = {"low": 0.6, "medium": 0.75, "high": 1.0}
        climate = {"optimistic": 1, "pessimistic": 0.75}

        # Adjust base values
        adj_baseServices = baseServices.copy()
        adj_baseServices['adj'] = adj_baseServices['sum'].mul(n_spp.get(input.richness()) * climate.get(input.ssp()))
        adj_baseServices['adj'] = adj_baseServices['adj'].mul(1 - (basePesticides['kgPerArea'].mul(input.pesticide())))

        return adj_baseServices

    @render.plot
    def service_plot():
        adjusted_baseServices = adjusted_services()
        
        ax = adjusted_baseServices.plot(
                column = 'adj',
                cmap = 'BrBG',
                edgecolor = 'black',
                figsize = (100,100),
                legend = True,
                legend_kwds = {"label": "Relative Pollination Services",
                               "orientation": "horizontal",
                               "shrink": 0.3},
                vmin=0, 
                vmax=1
                )
        
        ax.set_axis_off()
        return(ax)

    ####
    # @reactive.calc
    # def filtered_df() -> pd.DataFrame:
    #     filt_df = df[df["Species"].isin(input.species())]
    #     filt_df = filt_df.loc[filt_df["Body Mass (g)"] > input.mass()]
    #     return filt_df

    # @render.text
    # def adelie_count():
    #     return count_species(filtered_df(), "Adelie")

    # @render.text
    # def chinstrap_count():
    #     return count_species(filtered_df(), "Chinstrap")

    # @render.text
    # def gentoo_count():
    #     return count_species(filtered_df(), "Gentoo")

    # @render.plot
    # def length_depth():
    #     return sns.scatterplot(
    #         data=filtered_df(),
    #         x="Bill Length (mm)",
    #         y="Bill Depth (mm)",
    #         hue="Species",
    #     )

    # @render.data_frame
    # def summary_statistics():
    #     display_df = filtered_df()[
    #         [
    #             "Species",
    #             "Island",
    #             "Bill Length (mm)",
    #             "Bill Depth (mm)",
    #             "Body Mass (g)",
    #         ]
    #     ]
    #     return render.DataGrid(display_df, filters=True)


def count_species(df, species):
    return df[df["Species"] == species].shape[0]


app = App(app_ui, server)
