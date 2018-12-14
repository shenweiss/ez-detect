﻿using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;

namespace WpfApp1
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        private Dictionary<string, string> _args = new Dictionary<string, string>();
        private string _suggested_montage = "";
        private string _bp_montage = "";
        private string _trc_temp_path = "";

        private string[] _montage_names;

        public Dictionary<string, string> Args
        {
            get { return _args; }
            set { _args = value; }
        }
        public string suggestedMontage
        {
            get { return _suggested_montage; }
            set { _suggested_montage = value; }
        }
        public string bpMontage
        {
            get { return _bp_montage; }
            set { _bp_montage = value; }
        }
        public string trcTempPath
        {
            get { return _trc_temp_path; }
            set { _trc_temp_path = value; }
        }

        public string[] montageNames
        {
            get { return _montage_names; }
            set { _montage_names = value; }
        }
        

        protected override void OnStartup(StartupEventArgs e)
        {
            var args = e.Args;
            if (args != null && args.Count() > 0)
            {
                for (int index = 0; index < args.Length; index += 2)
                {
                    this.Args.Add(args[index], args[index + 1]);
                }
            }
            else
            {
                MessageBox.Show("Not enough arguments.");
            }
            string trc_path = this.Args["-trc"];
            string trc_fname = Path.GetFileNameWithoutExtension(@trc_path);
            string trc_temp_path = @"C:/System98/temp/" + trc_fname + ".TRC"; ; 
            System.IO.File.Copy(trc_path, trc_temp_path, true);//this is because as brainquick has the trc opened we can't use it to load names or scp... review
            this.trcTempPath = trc_temp_path;
            getMontages();

        }

        public void getMontages()
        {
            string pythonFullPath = @"C:\Users\Tomas Pastore\AppData\Local\Programs\Python\Python35\python.exe";

            ProcessStartInfo start = new ProcessStartInfo();
            start.FileName = Path.GetFileName(pythonFullPath);
            start.WorkingDirectory = Path.GetDirectoryName(pythonFullPath);
            string cmd = "C:/Program Files (x86)/Micromed/BrainQuick/Plugins/montage_names.py";
            string args = this.Args["-trc"];
            start.Arguments = string.Format("\"{0}\" \"{1}\"", cmd, args);
            start.UseShellExecute = false;// Do not use OS shell
            start.CreateNoWindow = true; // We don't need new window
            start.RedirectStandardOutput = true;// Any output, generated by application will be redirected back
            start.RedirectStandardError = true; // Any error in standard output will be redirected back (for example exceptions)
            using (Process process = Process.Start(start))
            {
                using (StreamReader reader = process.StandardOutput)
                {
                    string stderr = process.StandardError.ReadToEnd(); // Here are the exceptions from our Python script
                    string name_list = reader.ReadToEnd(); // Here is the result of StdOut(for example: print "test")
                    this.montageNames = name_list.Split(new[]{ ',' }, StringSplitOptions.RemoveEmptyEntries);
                }
            }
            
        }

        public void startEzDetect()
        {
            //Cargo parametros
            string trc_path = this.Args["-trc"];
            string trc_fname = Path.GetFileNameWithoutExtension(@trc_path);
            string trc_fname_withExt = trc_fname + ".TRC";
            string xml_out_path_real = this.Args["-xml"]; //donde lo voy a copiar despues por ssh
            string trc_temp_path = this.trcTempPath;
            
            //Creo un logfile muy rustico 
            string log_file = "C:/System98/temp/hfoAnnotate_log.txt"; //escribo aca temporalmente por un tema de permisos, en C:/ no se escribe.
            string createText = "INPUT TRC_PATH: " + @trc_path + Environment.NewLine + "INPUT XML_PATH: " + @xml_out_path_real + Environment.NewLine;
            File.WriteAllText(log_file, createText);

            //1)Copio el TRC al server
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@log_file, true)) { file.WriteLine("Copying TRC to the server..."); }
            ProcessStartInfo cmdsi1 = new ProcessStartInfo("pscp", @trc_temp_path + " " + "tpastore@grito.exp.dc.uba.ar:/home/tpastore/TRCs/" + trc_fname_withExt);
            Process cmd1 = Process.Start(cmdsi1);
            cmd1.WaitForExit();

            //2)Ejecuto por ssh
            //2.1 creo un file para el comando a ejecutar
            string command_file = "C:/System98/temp/hfoAnnotatePlugin_SSHcommand";
            string command = "./hfo_annotate.sh" +" "+ trc_fname +" "+ this.suggestedMontage +" "+ this.bpMontage;
            File.WriteAllText(command_file, command);
            //2.2)Run
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@log_file, true)) { file.WriteLine("Running hfoAnnotate app..."); }
            ProcessStartInfo cmdsi2 = new ProcessStartInfo("putty", "-load Grito -m " + @command_file);
            Process cmd2 = Process.Start(cmdsi2);
            cmd2.WaitForExit();

            //3)Terminada la ejecucion copio el xml de output al path real en brainQuick
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@log_file, true)) { file.WriteLine("Copying xml (.evt) to BrainQuick correct directory..."); }
            ProcessStartInfo cmdsi3 = new ProcessStartInfo("pscp", "tpastore@grito.exp.dc.uba.ar:/home/tpastore/" + trc_fname + "_xml_out.evt" + " " + @xml_out_path_real);
            Process cmd3 = Process.Start(cmdsi3);
            cmd3.WaitForExit();
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@log_file, true)) {file.WriteLine("Exiting from plugin."); }
        }
    }
}
