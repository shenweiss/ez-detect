using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace EzDetectGUI
{
    /// <summary>
    /// Interaction logic for Window1.xaml
    /// </summary>
    public partial class Window1 : Window
    {
        public App App { get; set; } = ((App)System.Windows.Application.Current);

        public Window1()
        {
            InitializeComponent();
        }
        private void Back_Button_Click(object sender, RoutedEventArgs e)
        {
            this.App.MainWindow.Show();
            this.Close();
        }


        private void Trc_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Remote_trc_dir= t.Text;
        }

        private void Evt_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Remote_evt_dir = t.Text;

        }

        private void Logfile_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Log_file = t.Text;
        }

        private void Command_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Command_file = t.Text;
        }

        private void Trc_temp_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.TrcTempDir = t.Text;
        }

        private void Hostname_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Hostname= t.Text;
        }
        private void Username_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Username = t.Text;
        }
        private void Host_conf_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Host_conf = t.Text;
        }

        private void Python_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Python_path = t.Text;
        }

        private void Scipts_TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextBox t = sender as TextBox;
            this.App.Scripts_path = t.Text;
        }
    }
}
