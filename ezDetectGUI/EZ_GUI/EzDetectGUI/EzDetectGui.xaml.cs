using CommandLine;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;

namespace EzDetectGUI
{
    /// Graphic user interface for Ez_detect application (HFO detector)
    public partial class App : Application
    {
        public string TrcFile { get; set; } = "";
        public string EvtFile{ get; set; } = "";
        public string TrcTempPath { get; set; } = "";
        public string SuggestedMontage { get; set; } = "";
        public string BpMontage { get; set; } = "";
        public int StartTime { get; set; } = 1;
        public int StopTime { get; set; } = 1;
        public int CycleTime { get; set; } = -1;

        public string Python_path { get; set; } = "C:/Users/Tomas Pastore/AppData/Local/Programs/Python/Python35/python.exe";
        public string Scripts_path { get; set; } = "C:/Program Files (x86)/Micromed/BrainQuick/Plugins/";

        public string Remote_trc_dir { get; set; } = "/home/tpastore/TRCs/";
        public string Remote_evt_dir { get; set; } = "/home/tpastore/evts/";

        public string Log_file { get; set; } = "C:/System98/temp/ez_detect_gui_log.txt";
        public string Command_file { get; set; } = "C:/System98/temp/hfoAnnotatePlugin_SSHcommand";
        public string TrcTempDir { get; set; } = "C:/System98/temp/";

        public string Hostname { get; set; } = "grito.exp.dc.uba.ar";
        public string Username { get; set; } = "tpastore";
        public string Host_conf { get; set; } = "Grito";


        class Options
        {
            [CommandLine.Option('t', "trc", Required = false,
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

        protected override void OnStartup(StartupEventArgs e)
        {
            var args = e.Args;
            CommandLine.Parser.Default.ParseArguments<Options>(args)
              .WithParsed<Options>(opts => RunOptionsAndReturnExitCode(opts))
              .WithNotParsed<Options>((errs) => HandleParseError(errs));
        }

        private void HandleParseError(IEnumerable<Error> errs)
        {
            //TODO
            throw new NotImplementedException();
        }

        private void RunOptionsAndReturnExitCode(Options opts)
        {
            if (!string.IsNullOrEmpty(opts.TrcFile)) this.TrcFile = (opts.TrcFile).Replace("\\", "/");
            if (!string.IsNullOrEmpty(opts.EvtFile)) this.EvtFile = (opts.EvtFile).Replace("\\", "/");
        }

        public void CopyTrc() {
            this.TrcTempPath = this.TrcTempDir + Path.GetFileName(this.TrcFile); 
            System.IO.File.Copy(this.TrcFile, this.TrcTempPath, true);
        }

        //TODO 
        //format strings
        //Change command .sh to .py
        public void RunEzDetect()
        {
            //Params
            string remote_trc_path = this.Remote_trc_dir + Path.GetFileName(this.TrcFile);
            string remote_xml_path = this.Remote_evt_dir + Path.GetFileNameWithoutExtension(this.TrcFile) + ".evt";

            string createText = "Input trc_path: " + this.TrcFile + Environment.NewLine + 
                                "Output xml_path: " + this.EvtFile + Environment.NewLine;
            File.WriteAllText(this.Log_file, createText);
            //1)Copy TRC to the server
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(this.Log_file, true)) { file.WriteLine("Copying TRC to the server..."); }
            ProcessStartInfo cmdsi_copy = new ProcessStartInfo("pscp", this.TrcTempPath + " " + this.Username + "@"+ this.Hostname + ":" + remote_trc_path);
            Process cmd_copy = Process.Start(cmdsi_copy);
            cmd_copy.WaitForExit(); 
            //var wnd = App.Current.MainWindow as MainWindow;
            //MainWindow wnd = (MainWindow)this.MainWindow;
            //wnd.UpdateProgress(15);

            //2)Exec through ssh
            //2.1 Create command file
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(this.Log_file, true)) { file.WriteLine("montages... "+ this.SuggestedMontage+ " " + this.BpMontage); }

            string command = "./hfo_annotate.sh" + " " +
                              remote_trc_path.Trim() + " " +
                              remote_xml_path.Trim() + " " +
                              this.StartTime.ToString().Trim() + " " +
                              this.StopTime.ToString().Trim() + " " +
                              this.CycleTime.ToString().Trim() + " " +
                              this.SuggestedMontage.Trim() + " " + 
                              this.BpMontage.Trim();

            File.WriteAllText(this.Command_file, command);
            //2.2)Run
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(this.Log_file, true)) { file.WriteLine("Running HfoAnnotate App..."); }
            ProcessStartInfo cmdsi_run = new ProcessStartInfo("putty", "-load "+ this.Host_conf + " -m " + this.Command_file);
            Process cmd_run = Process.Start(cmdsi_run);
            cmd_run.WaitForExit();

            //wnd.UpdateProgress(98);
        }

        public void CopyEvt()
        {
            string remote_xml_path = this.Remote_evt_dir + Path.GetFileNameWithoutExtension(this.TrcFile) + ".evt";
            string source_dest = this.Username + "@" + this.Hostname+ ":" + remote_xml_path + " " + "\"" + this.EvtFile + "\"";
            //3)After execution, fetch evt from remote_xml_path
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(this.Log_file, true)) { file.WriteLine("Getting evt from remote server..."); }
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(this.Log_file, true)) { file.WriteLine(source_dest); }

            ProcessStartInfo cmdsi_fetch_result = new ProcessStartInfo("pscp", source_dest);
            Process cmd_fetch_result = Process.Start(cmdsi_fetch_result);
            cmd_fetch_result.WaitForExit();
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(this.Log_file, true)) { file.WriteLine("Exiting."); }
            //wnd.CloseWithMessage("Calculation has finished. The events will automatically load to Brain Quick if the evt saving path was ok.");
        }
    }
}
