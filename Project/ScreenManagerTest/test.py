from kivy.app import App
from kivy.lang import Builder
from kivy.uix.screenmanager import ScreenManager, Screen

# Create both screens. Please note the root.manager.current: this is how
# you can control the ScreenManager from kv. Each screen has by default a
# property manager that gives you the instance of the ScreenManager used.
Builder.load_string("""
<SettingsScreen>:
    AnchorLayout:
        Label:
            font_size: 40
            center_x: root.width / 2
            top: root.top
            text: "Adhoc and Wireless Sensors Networks"

        Label:
            font_size: 20
            center_x: root.width / 2
            top: root.top - 50
            text: "Number of nodes in network = 2"

        Button:
            id: button_one
            center_x: root.width/4
            font_size: 20
            top: root.top - 200
            text: "Node 1"
            on_press: root.manager.current = 'node'

        Button:
            id: button_two
            font_size: 20
            top: root.top - 200
            center_x: 3* root.width/4
            text: "Node 2"
<MenuScreen>:
    AnchorLayout:
        Label:
            font_size: 40
            center_x: root.width / 2
            top: root.top
            text: "Adhoc and Wireless Sensors Networks"

        Label:
            font_size: 20
            center_x: root.width / 2
            top: root.top - 100
            text: "NODE ID = 1"

        Label:
            font_size: 20
            center_x: root.width / 2
            top: root.top - 150
            text: "Average Temp: 6389"

        Label:
            font_size: 20
            center_x: root.width / 2
            top: root.top - 200
            text: "Average Humidity: 450"

        Label:
            font_size: 20
            center_x: root.width / 2
            top: root.top - 250
            text: "Average Par: 20"

        Button:
            center_x: root.width/4
            font_size: 20
            top: root.top - 300
            text: "Back"
            on_press: root.manager.current = 'home'

""")

# Declare both screens
class MenuScreen(Screen):
    pass

class SettingsScreen(Screen):
    pass

# Create the screen manager
sm = ScreenManager()
sm.add_widget(MenuScreen(name='menu'))
sm.add_widget(SettingsScreen(name='settings'))

class TestApp(App):

    def build(self):
        return sm

if __name__ == '__main__':
    TestApp().run()