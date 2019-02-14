﻿using CommandLine;
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
            if (!string.IsNullOrEmpty(opts.TrcFile)) this.TrcFile = opts.TrcFile;
            if (!string.IsNullOrEmpty(opts.EvtFile)) this.EvtFile = opts.EvtFile;
        }

        public void CopyTrc() {
            this.TrcTempPath = "C:/Users/tpastore/Documents/TRCs/temp/" + Path.GetFileName(this.TrcFile);
            System.IO.File.Copy(this.TrcFile, this.TrcTempPath, true);
        }

        //TODO 
        //format strings
        //IMPROVE LOGS
        //Change command .sh to .py
        //make remote paths configurable, remote server and username
        public void RunEzDetect()
        {
            //Params
            string remote_trc_path = "/home/tpastore/TRCs/" + Path.GetFileName(this.TrcFile);
            string remote_xml_path = "/home/tpastore/evts/" + Path.GetFileNameWithoutExtension(this.TrcFile) + ".evt";

            string log_file = "C:/Users/tpastore/Documents/ez_detect_gui/ez_detect_gui_log.txt";
            string createText = "Input trc_path: " + this.TrcFile + Environment.NewLine + 
                                "Output xml_path: " + this.EvtFile + Environment.NewLine;
            File.WriteAllText(log_file, createText);

            //1)Copy TRC to the server
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) { file.WriteLine("Copying TRC to the server..."); }
            ProcessStartInfo cmdsi_copy = new ProcessStartInfo("pscp", this.TrcTempPath + " " + "tpastore@grito.exp.dc.uba.ar:" + remote_trc_path);
            Process cmd_copy = Process.Start(cmdsi_copy);
            cmd_copy.WaitForExit();

            //MainWindow wnd = (MainWindow)this.MainWindow;
            //wnd.UpdateProgress(15);
            
            //2)Exec through ssh
            //2.1 Create command file
            string command_file = "C:/Users/tpastore/Documents/ez_detect_gui/hfoAnnotatePlugin_SSHcommand";
            string command = "./hfo_annotate.sh" + " " +
                              remote_trc_path + " " +
                              remote_xml_path + " " +
                              this.StartTime.ToString() + " " +
                              this.StopTime.ToString() + " " +
                              this.CycleTime.ToString() + " " +
                              this.SuggestedMontage + " "+ this.BpMontage;

            File.WriteAllText(command_file, command);
            //2.2)Run
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) { file.WriteLine("Running HfoAnnotate App..."); }
            ProcessStartInfo cmdsi_run = new ProcessStartInfo("putty", "-load Grito -m " + command_file);
            Process cmd_run = Process.Start(cmdsi_run);
            cmd_run.WaitForExit();

            //wnd.UpdateProgress(98);

            //3)After execution, fetch evt from remote_xml_path
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) { file.WriteLine("Getting evt from remote server..."); }
            ProcessStartInfo cmdsi_fetch_result = new ProcessStartInfo("pscp", "tpastore@grito.exp.dc.uba.ar:"+ remote_xml_path + " " + this.EvtFile);
            Process cmd_fetch_result = Process.Start(cmdsi_fetch_result);
            cmd_fetch_result.WaitForExit();
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) {file.WriteLine("Exiting."); }

        }
    }
}
