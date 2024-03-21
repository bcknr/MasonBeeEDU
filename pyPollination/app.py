from pathlib import Path

import geopandas as gpd
import seaborn as sns

from shiny import App, Inputs, Outputs, Session, reactive, render, ui

sns.set_theme(style="white")
# df = pd.read_csv(Path(__file__).parent / "penguins.csv", na_values="NA")
baseServices = gpd.read_file(Path(__file__).parent / "data.gpkg", layer = 'geodata')
baseServices['adj'] = baseServices['base']

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
            ["high", "low"]
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
            ui.card_header(ui.h4("Pollination Services")),
            ui.output_plot("service_plot", width = "100%", height="800px"),
        ),
        ui.card(
            ui.card_header(ui.h4("Crop Growing Regions")),
            ui.layout_column_wrap(
                    ui.card(
                        ui.card_header("Apple"),
                        ui.output_plot("apple_plot", width = "100%", height="250px"),
                    ),
                    ui.card(
                        ui.card_header("Blueberry"),
                        ui.output_plot("blueberry_plot", width = "100%", height="250px"),
                    ),
                    ui.card(
                        ui.card_header("Alfalfa"),
                        ui.output_plot("alfalfa_plot", width = "100%", height="250px"),
                    ),
                    ui.card(
                        ui.card_header("Corn"),
                        ui.output_plot("corn_plot", width = "100%", height="250px"),
                    ),
                    width = 1 / 2,
            ),
        ),
    ),

    # ui.layout_columns(
    #     ui.value_box(
    #         title = "Apples",
    #         value = ui.output_ui("apples_count")
    #     )
    # ),

    ui.layout_columns(
        *[make_value_box(crop) for crop in species],
    ),

)


def server(input: Inputs, output: Outputs, session: Session):
    # Calculate modified pollination services

    @reactive.calc
    def adjusted_services():

        # Update reactive.value
        # update.set(not update())

        # Lookup parameters
        n_spp = {"low": 0.75, "high": 1.0}
        climate = {"optimistic": "ssp1", "pessimistic": "ssp5"}

        # Adjust base values
        adj_baseServices = baseServices.copy()

        # Richness, Climate change, and pesticide intensity
        adj_baseServices['adj'] = adj_baseServices['base'].mul(n_spp.get(input.richness()) * 
                                                              (1 - baseServices[climate.get(input.ssp())].mul(0.5)) *
                                                              (1 - (baseServices['kgPerArea'].mul(input.pesticide())))
                                                              )

        return adj_baseServices


    # Plot main map
    @render.plot
    def service_plot():
        adjusted_baseServices = adjusted_services()
        
        ax = adjusted_baseServices.plot(
                column = 'adj',
                cmap = 'BrBG',
                edgecolor = 'black',
                figsize = (100,75),
                legend = True,
                legend_kwds = {"label": "Relative Pollination Services",
                               "orientation": "horizontal",
                               "shrink": 0.3},
                vmin=0, 
                vmax=1
                )
        
        ax.set_axis_off()
        return(ax)
    
    # Plots of crop growing regions
    @render.plot
    def apple_plot():
        ax = baseServices.plot(
                column = 'apples',
                cmap = 'Greens',
                linewidth=0.1,
                edgecolor = 'black',
                legend = False
                )
        ax.set_axis_off()
        return(ax)
    
    @render.plot
    def blueberry_plot():
        ax = baseServices.plot(
                column = 'blueberries',
                cmap = 'Greens',
                linewidth=0.1,
                edgecolor = 'black',
                legend = False
                )
        ax.set_axis_off()
        return(ax)
    
    @render.plot
    def alfalfa_plot():
        ax = baseServices.plot(
                column = 'alfalfa',
                cmap = 'Greens',
                linewidth=0.1,
                edgecolor = 'black',
                legend = False
                )
        ax.set_axis_off()
        return(ax)
    
    @render.plot
    def corn_plot():
        ax = baseServices.plot(
                column = 'corn',
                cmap = 'Greens',
                linewidth=0.1,
                edgecolor = 'black',
                legend = False
                )
        ax.set_axis_off()
        return(ax)

    # Calculate mean and range of pollination

    @reactive.calc
    def crop_services():
        # Filter by crop, extract adjusted values
        adjusted_baseServices = adjusted_services()

        means = []
        for spp in species:
            means += [adjusted_baseServices[adjusted_baseServices[spp.lower()] == 1]["adj"].mean().round(2)]
        return means
    
    @render.text
    def apples_count():
        # Reduce when spring bee vuln increases
        val = crop_services()[0] - (input.spring_vuln() * crop_services()[0] / 2)
        return f"Mean: {val.round(2)}"
    
    @render.text
    def alfalfa_count():
        # Buffer for wind
        val = crop_services()[2] + 0.15
        return f"Mean: {val.round(2)}"
    
    @render.text
    def blueberries_count():
        # Reduce when buzz bee vuln increases
        val = crop_services()[1] - (input.buzz_vuln() * crop_services()[1] / 2)
        return f"Mean: {val.round(2)}"
    
    @render.text
    def corn_count():
        # Buffer for wind
        with reactive.isolate():
            val = crop_services()[3] + 0.11
        return f"Mean: {val}"

app = App(app_ui, server)
