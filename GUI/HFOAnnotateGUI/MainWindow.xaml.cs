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
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace WpfApp1
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    

    public partial class MainWindow : Window
    {
        private App _app = ((App)Application.Current);

        public MainWindow()
        {
            InitializeComponent();
        }

        public App App
        {
            get { return _app; }
            set { _app = value; }
        }

        public void CloseWithMessage(string msg)
        {
            MessageBox.Show(msg);
            this.Close();
        }

        private void suggested_montage_Loaded(object sender, RoutedEventArgs e)
        {
            foreach ( string name in this.App.montageNames )
            {
                suggested_montage.Items.Add(name);
            }
        }

        private void suggested_montage_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            ComboBox c = sender as ComboBox;
            this.App.suggestedMontage = c.SelectedItem.ToString();

        }

        private void bipolar_montage_Loaded(object sender, RoutedEventArgs e)
        {
            foreach (string name in this.App.montageNames)
            {
                bipolar_montage.Items.Add(name);
            }
        }

        private void bipolar_montage_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            ComboBox c = sender as ComboBox;
            this.App.bpMontage = c.SelectedItem.ToString();

        }

        private void runBtn_Click(object sender, RoutedEventArgs e)
        {
            if (this.App.suggestedMontage == "" || this.App.bpMontage == "")
            {
                MessageBox.Show("Montage selections are required.");
            }
            else
            {
                this.App.startEzDetect();
                this.CloseWithMessage("Calculation has finished. The events will automatically load to Brain Quick.");
            }
        }
    }
}
