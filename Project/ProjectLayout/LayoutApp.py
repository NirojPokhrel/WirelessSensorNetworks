from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import NumericProperty, ReferenceListProperty,\
    ObjectProperty

from kivy.lang import Builder

from kivy.uix.screenmanager import ScreenManager, Screen



class HomeScreen(Screen):
    pass

class NodeScreen(Screen):
    pass
#class LayoutWidget(Widget):
    #btn1 = ObjectProperty(None)
    #btn2 = ObjectProperty(None)

    #def btn1_callback(self, event):
    #    print('The button <%s> is being pressed' % self.btn1.text)

    #def btn2_callback(self, event):
    #    print('The button<%s> is being pressed' % self.btn2.text )

    #def start(self):
    #    self.btn1.bind(on_press=self.btn1_callback)
    #    self.btn2.bind(on_press=self.btn2_callback)

# Create the screen manager
sm = ScreenManager()
sm.add_widget(HomeScreen(name='home'))
sm.add_widget(NodeScreen(name='node'))


class LayoutApp(App):

    def build(self):
       # layout = LayoutWidget()
       # layout.start()
       # return layout

        return sm

if __name__ == '__main__':
    LayoutApp().run()