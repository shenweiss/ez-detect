﻿using System;
using System.Windows;
using System.Windows.Controls;
using System.ComponentModel;
using System.IO;
using Path = System.IO.Path;
using System.Diagnostics;
using System.Windows.Forms;

namespace EzDetectGUI
{
    /// Window objects

    public partial class MainWindow : Window, INotifyPropertyChanged
    {
        public App App { get; set; } = ((App)System.Windows.Application.Current);
        private BackgroundWorker _bgWorker = new BackgroundWorker();
        private int _workerState;
        public event PropertyChangedEventHandler PropertyChanged;
        public int WorkerState
        {
            get { return _workerState; }
            set
            {
                _workerState = value;
                if (PropertyChanged != null)
                    PropertyChanged(this, new PropertyChangedEventArgs("WorkerState"));
            }
        }
        public void UpdateProgress(int progressState) { this.WorkerState = progressState; }
        public string[] MontageNames { get; set; }
        public string RunPythonScript(string pythonPath, string scriptPath, string args)
        {
            ProcessStartInfo start = new ProcessStartInfo();
            start.FileName = Path.GetFileName(pythonPath);
            start.WorkingDirectory = Path.GetDirectoryName(pythonPath);
            start.Arguments = string.Format("\"{0}\" \"{1}\"", scriptPath, args);
            start.UseShellExecute = false;// Do not use OS shell
            start.CreateNoWindow = true; // We don't need new window
            start.RedirectStandardOutput = true;// Any output, generated by application will be redirected back
            start.RedirectStandardError = true; // Any error in standard output will be redirected back (for example exceptions)
            using (Process process = Process.Start(start))
            {
                using (StreamReader reader = process.StandardOutput)
                {
                    string stderr = process.StandardError.ReadToEnd(); // Here are the exceptions from our Python script
                    return reader.ReadToEnd(); // Here is the result of StdOut(for example: print "test")
                }
            }
        }
        public void GetMontages()
        {
            string pythonPath = "C:/Users/tpastore/AppData/Local/Programs/Python/Python35/python.exe";
            string scriptPath = "C:/Users/tpastore/Documents/ez_detect_gui/montage_names.py"; //returns comma separated name list
            string args = this.App.TrcTempPath;
            string script_stream = RunPythonScript(pythonPath, scriptPath, args);
            this.MontageNames = script_stream.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        }
        public void GetTrcDuration()
        {
            string pythonPath = "C:/Users/tpastore/AppData/Local/Programs/Python/Python35/python.exe"; 
            string scriptPath = "C:/Users/tpastore/Documents/ez_detect_gui/trc_duration.py";
            string args = this.App.TrcTempPath;
            string duration_snds = RunPythonScript(pythonPath, scriptPath, args);
            this.Slider_start.Maximum = double.Parse(duration_snds, System.Globalization.CultureInfo.InvariantCulture);
            this.Slider_stop.Maximum = this.Slider_start.Maximum;

        }

        public MainWindow()
        {
            InitializeComponent();
            DataContext = this;
            if (string.IsNullOrEmpty(this.App.TrcFile)) {
                System.Windows.MessageBox.Show("Please select a TRC file to analize.");

                OpenFileDialog openFileDialog1 = new OpenFileDialog
                {
                    Title = "Browse TRC",
                    CheckFileExists = true,
                    CheckPathExists = true,
                    DefaultExt = "TRC",
                    Filter = "TRC files(*.TRC)| *.TRC",
                    FilterIndex = 2,
                    RestoreDirectory = true,
                };
                if (openFileDialog1.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                {
                    this.TrcLabel.Content = openFileDialog1.FileName;
                    this.App.TrcFile = (string)this.TrcLabel.Content;
                }
            } else {
                this.TrcLabel.Content = Path.GetFileName(this.App.TrcFile);
            }
            if (string.IsNullOrEmpty(this.App.EvtFile)) {

                System.Windows.MessageBox.Show("Please select the evt saving directory.");
                var dialog = new FolderBrowserDialog();
                dialog.ShowDialog();
                this.EvtLabel.Content = dialog.SelectedPath + "\\" + Path.GetFileNameWithoutExtension(this.App.TrcFile) + ".evt";
                this.App.EvtFile = (string)@EvtLabel.Content;
            } else {
                this.EvtLabel.Content = this.App.EvtFile;
            }
            //TODO extract path from window
            this.App.CopyTrc();
            GetMontages();
            GetTrcDuration();
            UpdateProgress(5);
        }

        //******************************   EVENTS   ******************************

        //TRC
        private void SearchTRC_Button_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog openFileDialog1 = new OpenFileDialog
            {
                Title = "Browse TRC",
                CheckFileExists = true,
                CheckPathExists = true,
                DefaultExt = "TRC",
                Filter = "TRC files(*.TRC)| *.TRC",
                FilterIndex = 2,
                RestoreDirectory = true,
            };
            if (openFileDialog1.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                this.TrcLabel.Content = openFileDialog1.FileName;
                this.App.TrcFile = (string)this.TrcLabel.Content;
            }
        }
        //EVT
        private void SearchEvt_Button_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(this.App.TrcFile))
            {
                System.Windows.MessageBox.Show("Please select a TRC file prior to setting the evt saving path.");
            }
            var dialog = new FolderBrowserDialog();
            dialog.ShowDialog();
            this.EvtLabel.Content = dialog.SelectedPath + "\\" + Path.GetFileNameWithoutExtension(this.App.TrcFile) + ".evt";
            this.App.EvtFile = (string)@EvtLabel.Content;
        }


        //Montages
        private void ComboBox_suggested_montage_Loaded(object sender, RoutedEventArgs e)
        {
            foreach ( string name in this.MontageNames )
            {
                ComboBox_suggested_montage.Items.Add(name);
            }
        }

        private void ComboBox_suggested_montage_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            System.Windows.Controls.ComboBox c = sender as System.Windows.Controls.ComboBox;
            this.App.SuggestedMontage = c.SelectedItem.ToString();

        }
        private void ComboBox_bp_montage_Loaded(object sender, RoutedEventArgs e)
        {
            foreach (string name in this.MontageNames)
            {
                ComboBox_bp_montage.Items.Add(name);
            }
        }
        private void ComboBox_bp_montage_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            System.Windows.Controls.ComboBox c = sender as System.Windows.Controls.ComboBox;
            this.App.BpMontage = c.SelectedItem.ToString();

        }

        //TIME_WINDOW (START AND STOP TIME)
        private void Slider_start_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            Slider s = sender as Slider;
            this.App.StartTime = (int)s.Value;
        }
        private void Slider_stop_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            Slider s = sender as Slider;
            this.App.StopTime = (int)s.Value;
        }

        //Paralellizing with cycle time
        private void Chk_box_run_parallel_Checked(object sender, RoutedEventArgs e)
        {
            this.c_time_1_rBtn.IsEnabled = true;
            this.c_time_2_rBtn.IsEnabled = true;
            this.c_time_3_rBtn.IsEnabled = true;
            this.c_time_4_rBtn.IsEnabled = true;
        }

        private void Chk_box_run_parallel_Unchecked(object sender, RoutedEventArgs e)
        {
            this.c_time_1_rBtn.IsChecked = false;
            this.c_time_2_rBtn.IsChecked = false;
            this.c_time_3_rBtn.IsChecked = false;
            this.c_time_4_rBtn.IsChecked = false;
            this.App.CycleTime = -1;

            this.c_time_1_rBtn.IsEnabled = false;
            this.c_time_2_rBtn.IsEnabled = false;
            this.c_time_3_rBtn.IsEnabled = false;
            this.c_time_4_rBtn.IsEnabled = false;
        }

        private void RadioButton_1_Checked(object sender, RoutedEventArgs e)
        {
            System.Windows.Controls.RadioButton r = sender as System.Windows.Controls.RadioButton;
            this.App.CycleTime = Convert.ToInt32(r.Content) * 60;
        }
        private void RadioButton_2_Checked(object sender, RoutedEventArgs e)
        {
            System.Windows.Controls.RadioButton r = sender as System.Windows.Controls.RadioButton;
            this.App.CycleTime = Convert.ToInt32(r.Content) * 60;
        }
        private void RadioButton_3_Checked(object sender, RoutedEventArgs e)
        {
            System.Windows.Controls.RadioButton r = sender as System.Windows.Controls.RadioButton;
            this.App.CycleTime = Convert.ToInt32(r.Content) * 60;
        }
        private void RadioButton_4_Checked(object sender, RoutedEventArgs e)
        {
            System.Windows.Controls.RadioButton r = sender as System.Windows.Controls.RadioButton;
            this.App.CycleTime = Convert.ToInt32(r.Content) * 60;
        }
        
        //RUN BUTTON
        public void CloseWithMessage(string msg)
        {
            System.Windows.MessageBox.Show(msg);
            this.Close();
        }
        //TODO
        //use log module 
        private void RunBtn_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(this.App.TrcFile) || string.IsNullOrEmpty(this.App.EvtFile))
            {
                System.Windows.MessageBox.Show("Please select a TRC file and set the evt saving path.");
            }
            if (this.App.SuggestedMontage == "" || this.App.BpMontage == "")
            {
                System.Windows.MessageBox.Show("Montage selections are required.");
            }
            else if (this.App.StartTime > this.App.StopTime)
            {
                System.Windows.MessageBox.Show("Stop time must be greater or equal to start time.");
            }
            else if ((bool)this.Chk_box_run_parallel.IsChecked && this.App.CycleTime == -1)
            {
                System.Windows.MessageBox.Show("Please select a cycle time.");
            }
            else
            {
                if (this.App.CycleTime == -1) this.App.CycleTime = this.App.StopTime - this.App.StartTime + 1;
                _bgWorker.DoWork += (s, f) =>
                {
                    this.App.RunEzDetect();
                    this.UpdateProgress(100);

                };
                _bgWorker.RunWorkerAsync();
                //CloseWithMessage("Calculation has finished. The events will automatically load to Brain Quick if the evt saving path was ok.");


            }
        }

        
    }
}