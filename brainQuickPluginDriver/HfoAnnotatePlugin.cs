using Micromed.EventCalculation.Common;
using Micromed.ExternalCalculation.Common.Dto;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Micromed.ExternalCalculation.DemoIIExternalCalculation
{
    public class DemoIIPlugin : IExternalCalculationPlugin
    {
        public Guid Guid { get; private set; }
        public string Name { get; private set; }
        public string Description { get; private set; }
        public string Author { get; private set; }
        public string Version { get; private set; }

        private bool isRunning = false;

        private void CallHFOAnnotate(PluginParametersDto pluginParameters)
        {
            //Cargo parametros
            //string trc_path = pluginParameters.ExchangeTraceFilePathList[0];
            string trc_path = "\"" + (pluginParameters.TraceFilePathList[0]).Replace("\\","/") + "\"";
            string xml_out_path_real = "\"" + (pluginParameters.ExchangeEventFilePath).Replace("\\","/") + "\""; //donde lo voy a copiar despues por ssh
            string fullPath = "C:/Program Files (x86)/Micromed/BrainQuick/Plugins/EzDetectGUI.exe";
            //string fullPath = @"%windir%\system32\notepad.exe";
            string args = "--trc=" + trc_path + " --xml=" + xml_out_path_real;
            string log_file = "C:/System98/temp/ez_detect_PLUG_LOG.txt";
            string createText = args;
            File.WriteAllText(log_file, createText);

            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = Path.GetFileName(fullPath),
                WorkingDirectory = Path.GetDirectoryName(fullPath),
                Arguments = "--trc=" + trc_path + " --xml=" + xml_out_path_real
            };
            Process cmd = Process.Start(psi);
            cmd.WaitForExit();
        }

        public DemoIIPlugin()
        {
            Guid = Guid.Parse("1BC8E16D-3C09-40BE-8EC2-F9D7E6F0117C");
            Name = "HFO Annotate - Demo II";
            Description = "HfoAnnotate Test | External Calculation plugin";
            Author = "TJU|UBA";
            System.Reflection.Assembly assembly = System.Reflection.Assembly.GetExecutingAssembly();
            FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(assembly.Location);
            Version = fvi.FileVersion;
        }


        public int Start(PluginParametersDto pluginParameters)
        {
            if (isRunning)
                return 1; //isrunning

            isRunning = true; //esto creo que deberia ir antes del run command, en el mock plugin estaba despues

            CallHFOAnnotate(pluginParameters);

            OnProgress(100);
            return 0;
        }

        public bool Stop()
        {
            if (!isRunning)
                return false;

            isRunning = false;

            OnCancelled();
            return true;
        }


        public event EventHandler Completed;
        protected void OnCompleted()
        {
            EventHandler handler = Completed;
            if (handler != null) handler(this, null);
        }

        public event EventHandler Cancelled;
        protected void OnCancelled()
        {
            EventHandler handler = Cancelled;
            if (handler != null) handler(this, null);
        }

        public event EventHandler<string> Error;
        protected void OnError(string e)
        {
            EventHandler<string> handler = Error;
            if (handler != null) handler(this, e);
        }

        public event EventHandler<int> Progress;
        protected void OnProgress(int e)
        {
            EventHandler<int> handler = Progress;
            if (handler != null) handler(this, e);
        }


        public bool NeedTraceFilePathList
        {
            get { return true; } // original input trc
        }

        public bool NeedExchangeTraceFilePathList
        {
            get { return false; } //filtered
        }

        public bool NeedExchangeEventFilePath
        {
            get { return true; } //the output xml 
        }

        public bool NeedExchangeReportFilePath
        {
            get { return false; }
        }

        public bool NeedExchangeTrendFilePathList
        {
            get { return false; }
        }

        public bool NeedFilteredData
        {
            get { return false; }//If Brain Quick needs to filter data (used to create exchange trace file)
        }

        public bool DerivationOptionEnabled
        {
            get { return false; } //filter channels
        }

        public bool TraceSelectionOptionEnabled
        {
            get { return false; } //filter time window
        }
    }
}
