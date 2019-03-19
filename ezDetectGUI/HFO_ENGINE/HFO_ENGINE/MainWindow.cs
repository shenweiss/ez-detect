using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.Threading;


namespace HFO_ENGINE

{
    public partial class MainWindow : Form, INotifyPropertyChanged
    {
        public MainWindow()
        {
            InitializeComponent();
        }

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

        private void btnCerrar_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        public CycleTime CycleTime_Form;

        private void btnMaximizar_Click(object sender, EventArgs e)
        {
            this.WindowState = FormWindowState.Maximized;
            btnMaximizar.Visible = false;
            btnRestaurar.Visible = true;
        }

        private void btnRestaurar_Click(object sender, EventArgs e)
        {
            this.WindowState = FormWindowState.Normal;
            btnRestaurar.Visible = false;
            btnMaximizar.Visible = true;
        }

        private void btnMinimizar_Click(object sender, EventArgs e)
        {
            this.WindowState = FormWindowState.Minimized;
        }
        private void btnsalir_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }
        private void BarraTitulo_MouseDown(object sender, MouseEventArgs e)
        {
            ReleaseCapture();
            SendMessage(this.Handle, 0x112, 0xf012, 0);
        }


        [DllImport("user32.DLL", EntryPoint = "ReleaseCapture")]
        private extern static void ReleaseCapture();
        [DllImport("user32.DLL", EntryPoint = "SendMessage")]

        private extern static void SendMessage(System.IntPtr hWnd, int wMsg, int wParam, int lParam);
     
        private void AbrirFormHija(object formhija)
        {
            if (this.panelContenedor.Controls.Count > 0)
                this.panelContenedor.Controls.RemoveAt(0);
            Form fh = formhija as Form;
            fh.TopLevel = false;
            fh.Dock = DockStyle.Fill;
            this.panelContenedor.Controls.Add(fh);
            this.panelContenedor.Tag = fh;
            fh.Show();
        }
        private void BtnEEG_Click(object sender, EventArgs e)
        {
            AbrirFormHija(new EEG());
        }

        private void BtnMontage_Click(object sender, EventArgs e)
        {
            AbrirFormHija(new Montage());
        }

        private void BtnTimeWindow_Click(object sender, EventArgs e)
        {
            AbrirFormHija(new TimeWindow());
        }
        private void BtnMultiprocessing_Click(object sender, EventArgs e)
        {
            CycleTime_Form = new CycleTime();
            AbrirFormHija(CycleTime_Form);
        }

        private void BtnSSH_Click(object sender, EventArgs e)
        {
            AbrirFormHija(new SSH());
        }

        private void BtnOutput_Click(object sender, EventArgs e)
        {
            AbrirFormHija(new EVT());
        }

        private void BtnAdvancedSettings_Click(object sender, EventArgs e)
        {
            AbrirFormHija(new AdvancedSettings());
        }

        private void StartBtn_Click(object sender, EventArgs e)
        {

            if (Program.IsAnalizing)
            {
                AbrirFormHija(Program.ProgressScreen);
            }
            else
            {
                if (string.IsNullOrEmpty(Program.TrcFile) || string.IsNullOrEmpty(Program.EvtFile))
                {
                    MessageBox.Show("Please select a TRC file and set the evt saving path.");
                }
                if (Program.SuggestedMontage == "" || Program.BpMontage == "")
                {
                    MessageBox.Show("Montage selections are required.");
                }
                else if (Program.StartTime >= Program.StopTime)
                {
                    MessageBox.Show("Stop time must be greater than Start time.");
                }
                else if ((bool)Program.MultiProcessingEnabled && Program.CycleTime == -1)
                {
                    MessageBox.Show("Please select a cycle time.");
                }
                else
                {
                    if (Program.CycleTime == -1) Program.CycleTime = Program.StopTime - Program.StartTime + 1;
                    Program.IsAnalizing = true;
                    Program.ProgressScreen = new Progress();
                    this.UpdateProgress(1);
                    new Thread(() =>
                    {
                        Thread.CurrentThread.IsBackground = true;
                        _bgWorker.DoWork += (s, f) =>
                        {
                            Program.RunEzDetect();
                            Program.CopyEvt();
                            this.UpdateProgress(100);
                            Program.IsAnalizing = false;
                        };
                        _bgWorker.RunWorkerAsync();

                    }).Start();
                    AbrirFormHija(Program.ProgressScreen);

                }
                //CloseWithMessage("Calculation has finished. The events will automatically load to Brain Quick if the evt saving path was ok.");

            }

        }
    }
}
