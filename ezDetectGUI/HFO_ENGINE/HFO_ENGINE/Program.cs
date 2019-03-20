﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using CommandLine;

namespace HFO_ENGINE
{
    static class Program
    {
        public static string TrcFile { get; set; } = "";

        public static string SuggestedMontage { get; set; } = "Ref.";
        public static string BpMontage { get; set; } = "Ref.";

        public static int StartTime { get; set; } = 1;
        public static int StopTime { get; set; } = 1;
        public static int CycleTime { get; set; } = -1;
       
        public static string Hostname { get; set; } = "grito.exp.dc.uba.ar";
        public static string Username { get; set; } = "tpastore";
        public static string Host_conf { get; set; } = "Grito";
        public static string Remote_trc_dir { get; set; } = "/home/tpastore/TRCs/";
        public static string Remote_evt_dir { get; set; } = "/home/tpastore/evts/";

        public static string EvtFile { get; set; } = "";

        public static string Python_path { get; set; } = "C:/Users/tpastore/AppData/Local/Programs/Python/Python35/python.exe";
        public static string Scripts_path { get; set; } = "C:/Users/tpastore/source/repos/HFO_ENGINE/scripts/";
        public static string Log_file { get; set; } = "C:/Users/tpastore/source/repos/HFO_ENGINE/temp/ez_detect_gui_log.txt";
        public static string Command_file { get; set; } = "C:/Users/tpastore/source/repos/HFO_ENGINE/temp/hfoAnnotatePlugin_SSHcommand";
        public static string TrcTempDir { get; set; } = "C:/Users/tpastore/source/repos/HFO_ENGINE/temp/";
        public static string TrcTempPath { get; set; } = "";
        public static int Trc_duration { get; set; } = 0;

        public static string[] Montage_names;
        public static bool MultiProcessingEnabled{ get; set; } = false;
        public static int CycleTimeMin { get; set; } = 0;
        public static Form mainForm;
        public static Progress ProgressScreen;
        public static bool IsAnalizing { get; set; } = false;




        class Options
        {
            [Option('t', "trc", Required = false,
             HelpText = "Full path to input trc file to be processed.")]
            public string TrcFile { get; set; }

            [Option('x', "xml", Required = false,
              HelpText = "Full path to output evt file to be saved.")]
            public string EvtFile { get; set; }

            // Omitting long name, defaults to name of property, ie "--verbose"
            [Option(
              Default = false,
              HelpText = "Prints all messages to standard output.")]
            public bool Verbose { get; set; }
        }

        private static void HandleParseError(IEnumerable<Error> errs)
        {
            //TODO
            throw new NotImplementedException();
        }

        private static void RunOptionsAndReturnExitCode(Options opts)
        {
            if (!string.IsNullOrEmpty(opts.TrcFile)) TrcFile = (opts.TrcFile).Replace("\\", "/");
            if (!string.IsNullOrEmpty(opts.EvtFile)) EvtFile = (opts.EvtFile).Replace("\\", "/");
        }

        public static void CopyTRCLocally()
        {
            TrcTempPath = TrcTempDir + Path.GetFileName(TrcFile);
            File.Copy(TrcFile, TrcTempPath, true);
        }


        public static string RunPythonScript(string pythonPath, string scriptPath, string args)
        {
            ProcessStartInfo start = new ProcessStartInfo
            {
                FileName = Path.GetFileName(pythonPath),
                WorkingDirectory = Path.GetDirectoryName(pythonPath),
                Arguments = string.Format("\"{0}\" \"{1}\"", scriptPath, args),
                UseShellExecute = false,// Do not use OS shell
                CreateNoWindow = true, // We don't need new window
                RedirectStandardOutput = true,// Any output, generated by application will be redirected back
                RedirectStandardError = true // Any error in standard output will be redirected back (for example exceptions)
            };
            
            using (Process process = Process.Start(start)) //Controlar excepcion si esta mal el path
            {
                using (StreamReader reader = process.StandardOutput)
                {
                    string stderr = process.StandardError.ReadToEnd(); // Here are the exceptions from our Python script
                    return reader.ReadToEnd(); // Here is the result of StdOut(for example: print "test")
                }
            }
        }

        public static void GetTrcDuration()
        {
            string scriptPath = Scripts_path + "trc_duration.py";
            string args = TrcTempPath;
            string duration_snds = RunPythonScript(Python_path, scriptPath, args);

            Trc_duration = Convert.ToInt32(duration_snds);

        }
        public static void GetMontages()
        {
            string scriptPath = Scripts_path + "montage_names.py"; //returns comma separated name list
            string args = TrcTempPath;
            string script_stream = RunPythonScript(Python_path, scriptPath, args);

            Montage_names = script_stream.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        }

        public static void load_trc_data()
        {
            CopyTRCLocally();
            GetMontages();
            GetTrcDuration();
        }
        public static void RunEzDetect()
        {
            //Params
            string remote_trc_path = Remote_trc_dir + Path.GetFileName(TrcFile);
            string remote_xml_path = Remote_evt_dir + Path.GetFileNameWithoutExtension(TrcFile) + ".evt";

            string createText = "Input trc_path: " + TrcFile + Environment.NewLine +
                                "Output xml_path: " + EvtFile + Environment.NewLine;
            File.WriteAllText(Log_file, createText);

            //1)Copy TRC to the server
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(Log_file, true)) { file.WriteLine("Copying TRC to the server..."); }
            ProcessStartInfo cmdsi_copy = new ProcessStartInfo("pscp", TrcTempPath + " " + Username + "@" + Hostname + ":" + remote_trc_path);
            Process cmd_copy = Process.Start(cmdsi_copy);
            cmd_copy.WaitForExit();
            //var wnd = App.Current.MainWindow as MainWindow;
            //MainWindow wnd = (MainWindow)this.MainWindow;
            //wnd.UpdateProgress(15);

            //2)Exec through ssh
            //2.1 Create command file
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(Log_file, true)) { file.WriteLine("montages... " + SuggestedMontage + " " + BpMontage); }

            string command = "./hfo_annotate.sh" + " " +
                              remote_trc_path.Trim() + " " +
                              remote_xml_path.Trim() + " " +
                              StartTime.ToString().Trim() + " " +
                              StopTime.ToString().Trim() + " " +
                              CycleTime.ToString().Trim() + " " +
                              SuggestedMontage.Trim() + " " +
                              BpMontage.Trim();

            File.WriteAllText(Command_file, command);
            //2.2)Run
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(Log_file, true)) { file.WriteLine("Running HfoAnnotate App..."); }
            ProcessStartInfo cmdsi_run = new ProcessStartInfo("putty", "-load " + Host_conf + " -m " + "\"" + Command_file + "\"");
            Process cmd_run = Process.Start(cmdsi_run);
            cmd_run.WaitForExit();

            //wnd.UpdateProgress(98);
        }

        public static void CopyEvt()
        {
            string remote_xml_path = Remote_evt_dir + Path.GetFileNameWithoutExtension(TrcFile) + ".evt";
            string source_dest = Username + "@" + Hostname + ":" + remote_xml_path + " " + "\"" + EvtFile + "\"";
            //3)After execution, fetch evt from remote_xml_path
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(Log_file, true)) { file.WriteLine("Getting evt from remote server..."); }
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(Log_file, true)) { file.WriteLine(source_dest); }

            ProcessStartInfo cmdsi_fetch_result = new ProcessStartInfo("pscp", source_dest);
            Process cmd_fetch_result = Process.Start(cmdsi_fetch_result);
            cmd_fetch_result.WaitForExit();
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(Log_file, true)) { file.WriteLine("Exiting."); }
            //wnd.CloseWithMessage("Calculation has finished. The events will automatically load to Brain Quick if the evt saving path was ok.");
        }

        /// <summary>
        /// Punto de entrada principal para la aplicación.
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            Parser.Default.ParseArguments<Options>(args)
              .WithParsed<Options>(opts => RunOptionsAndReturnExitCode(opts))
              .WithNotParsed<Options>((errs) => HandleParseError(errs));

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            if (!String.IsNullOrEmpty(TrcFile)) load_trc_data();
            mainForm  = new MainWindow();
            Application.Run(mainForm);

            
        }
    }
}
