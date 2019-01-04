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
        public Dictionary<string, string> Args { get; set; } = new Dictionary<string, string>();
        public string TrcTempPath { get; set; } = "";
        public string SuggestedMontage { get; set; } = "";
        public string BpMontage { get; set; } = "";
        public int StartTime { get; set; } = 1;
        public int StopTime { get; set; } = 1;
        public int CycleTime { get; set; } = -1;
        protected override void OnStartup(StartupEventArgs e)
        {
            //TODO
            //IMPROVE ARGS VALIDATION
            //Make possible to pass no parameters and select trc and out path
            var args = e.Args;
            if (args != null && args.Count() > 0)
            {
                for (int index = 0; index < args.Length; index += 2)
                {
                    this.Args.Add(args[index], @args[index + 1]);
                }
            }
            else
            {
                MessageBox.Show("Not enough arguments.");
            }
            this.TrcTempPath = "C:/Users/tpastore/Documents/TRCs/temp/" + Path.GetFileNameWithoutExtension(this.Args["-trc"]) + ".TRC"; ;
            //This is because as brainquick has the trc opened we can't use it to load names or scp... review
            System.IO.File.Copy(this.Args["-trc"], this.TrcTempPath, true);
        }

        //TODO 
        //format strings
        //extract params
        //IMPROVE LOGS
        //Change command .sh to .py
        public void RunEzDetect()
        {
            //Params
            string trc_path = this.Args["-trc"];
            string trc_fname = Path.GetFileNameWithoutExtension(trc_path);
            string trc_fname_withExt = trc_fname + ".TRC";
            string remote_trc_path = "/home/tpastore/TRCs/" + trc_fname + ".TRC";
            string remote_xml_path = "/home/tpastore/" + trc_fname + ".evt";
            string xml_out_path_real = this.Args["-xml"]; //Where to copy the output
            
            string log_file = "C:/Users/tpastore/Documents/ez_detect_gui/ez_detect_gui_log.txt";
            string createText = "Input trc_path: " + this.Args["-trc"] + Environment.NewLine + 
                                "Input xml_path: " + this.Args["-xml"] + Environment.NewLine;
            File.WriteAllText(log_file, createText);

            //1)Copy TRC to the server
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) { file.WriteLine("Copying TRC to the server..."); }
            ProcessStartInfo cmdsi_copy = new ProcessStartInfo("pscp", this.TrcTempPath + " " + "tpastore@grito.exp.dc.uba.ar:" + remote_trc_path);
            Process cmd_copy = Process.Start(cmdsi_copy);
            cmd_copy.WaitForExit();

            MainWindow wnd = (MainWindow)this.MainWindow;
            wnd.UpdateProgress(15);
            
            //2)Exec through ssh
            //2.1 Create command file
            string command_file = "C:/Users/tpastore/Documents/ez_detect_gui/hfoAnnotatePlugin_SSHcommand";
            string command = "./hfo_annotate.sh" + " " +
                              remote_trc_path + " " +
                              remote_xml_path + " " +
                              this.StartTime.ToString() + " " +
                              this.StopTime.ToString() + " " +
                              this.CycleTime.ToString() + " " +
                              this.SuggestedMontage + " " +
                              this.BpMontage;

            File.WriteAllText(command_file, command);
            //2.2)Run
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) { file.WriteLine("Running HfoAnnotate App..."); }
            ProcessStartInfo cmdsi_run = new ProcessStartInfo("putty", "-load Grito -m " + command_file);
            Process cmd_run = Process.Start(cmdsi_run);
            cmd_run.WaitForExit();

            wnd.UpdateProgress(98);

            //3)After execution, fetch evt from remote_xml_path
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) { file.WriteLine("Getting evt from remote server..."); }
            ProcessStartInfo cmdsi_fetch_result = new ProcessStartInfo("pscp", "tpastore@grito.exp.dc.uba.ar:/home/tpastore/" + trc_fname + "_xml_out.evt" + " " + @xml_out_path_real);
            Process cmd_fetch_result = Process.Start(cmdsi_fetch_result);
            cmd_fetch_result.WaitForExit();
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(log_file, true)) {file.WriteLine("Exiting."); }

            wnd.CloseWithMessage("Calculation has finished. The events will automatically load to Brain Quick.");
        }
    }
}
