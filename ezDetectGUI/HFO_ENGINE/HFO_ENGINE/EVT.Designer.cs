namespace HFO_ENGINE
{
    partial class EVT
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(EVT));
            this.Evt_save_btn = new System.Windows.Forms.Button();
            this.EVT_title = new System.Windows.Forms.Label();
            this.EVTExportLabel = new System.Windows.Forms.Label();
            this.panel2 = new System.Windows.Forms.Panel();
            this.exportEVTbtn = new System.Windows.Forms.PictureBox();
            this.line = new System.Windows.Forms.Label();
            this.EvtPath_txtBx = new System.Windows.Forms.TextBox();
            this.panel2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.exportEVTbtn)).BeginInit();
            this.SuspendLayout();
            // 
            // Evt_save_btn
            // 
            this.Evt_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.Evt_save_btn.FlatAppearance.BorderSize = 2;
            this.Evt_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Evt_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.Evt_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Evt_save_btn.Location = new System.Drawing.Point(278, 286);
            this.Evt_save_btn.Name = "Evt_save_btn";
            this.Evt_save_btn.Size = new System.Drawing.Size(82, 34);
            this.Evt_save_btn.TabIndex = 10;
            this.Evt_save_btn.Text = "Save";
            this.Evt_save_btn.UseVisualStyleBackColor = true;
            this.Evt_save_btn.Click += new System.EventHandler(this.Evt_save_btn_Click);
            // 
            // EVT_title
            // 
            this.EVT_title.BackColor = System.Drawing.Color.Transparent;
            this.EVT_title.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.EVT_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.EVT_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.EVT_title.Location = new System.Drawing.Point(45, 55);
            this.EVT_title.Name = "EVT_title";
            this.EVT_title.Size = new System.Drawing.Size(148, 37);
            this.EVT_title.TabIndex = 9;
            this.EVT_title.Text = "EVT output";
            // 
            // EVTExportLabel
            // 
            this.EVTExportLabel.BackColor = System.Drawing.Color.Transparent;
            this.EVTExportLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.EVTExportLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.EVTExportLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.EVTExportLabel.Location = new System.Drawing.Point(0, 0);
            this.EVTExportLabel.Name = "EVTExportLabel";
            this.EVTExportLabel.Size = new System.Drawing.Size(140, 26);
            this.EVTExportLabel.TabIndex = 6;
            this.EVTExportLabel.Text = "Output EVT path";
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.line);
            this.panel2.Controls.Add(this.EvtPath_txtBx);
            this.panel2.Controls.Add(this.exportEVTbtn);
            this.panel2.Controls.Add(this.Evt_save_btn);
            this.panel2.Controls.Add(this.EVTExportLabel);
            this.panel2.Location = new System.Drawing.Point(55, 150);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 320);
            this.panel2.TabIndex = 11;
            // 
            // exportEVTbtn
            // 
            this.exportEVTbtn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.exportEVTbtn.Image = ((System.Drawing.Image)(resources.GetObject("exportEVTbtn.Image")));
            this.exportEVTbtn.InitialImage = ((System.Drawing.Image)(resources.GetObject("exportEVTbtn.InitialImage")));
            this.exportEVTbtn.Location = new System.Drawing.Point(150, 50);
            this.exportEVTbtn.Name = "exportEVTbtn";
            this.exportEVTbtn.Size = new System.Drawing.Size(50, 50);
            this.exportEVTbtn.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.exportEVTbtn.TabIndex = 11;
            this.exportEVTbtn.TabStop = false;
            this.exportEVTbtn.Click += new System.EventHandler(this.exportEVTbtn_Click_1);
            this.exportEVTbtn.MouseEnter += new System.EventHandler(this.exportEVTbtn_MouseEnter);
            this.exportEVTbtn.MouseLeave += new System.EventHandler(this.exportEVTbtn_MouseLeave);
            // 
            // line
            // 
            this.line.BackColor = System.Drawing.Color.White;
            this.line.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.line.Location = new System.Drawing.Point(5, 172);
            this.line.Name = "line";
            this.line.Size = new System.Drawing.Size(350, 2);
            this.line.TabIndex = 13;
            // 
            // EvtPath_txtBx
            // 
            this.EvtPath_txtBx.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.EvtPath_txtBx.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.EvtPath_txtBx.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.EvtPath_txtBx.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F);
            this.EvtPath_txtBx.ForeColor = System.Drawing.SystemColors.Window;
            this.EvtPath_txtBx.Location = new System.Drawing.Point(5, 147);
            this.EvtPath_txtBx.Name = "EvtPath_txtBx";
            this.EvtPath_txtBx.ScrollBars = System.Windows.Forms.ScrollBars.Horizontal;
            this.EvtPath_txtBx.Size = new System.Drawing.Size(350, 17);
            this.EvtPath_txtBx.TabIndex = 12;
            // 
            // EVT
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.EVT_title);
            this.Controls.Add(this.panel2);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "EVT";
            this.Text = "EVT";
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.exportEVTbtn)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button Evt_save_btn;
        private System.Windows.Forms.Label EVT_title;
        private System.Windows.Forms.Label EVTExportLabel;
        private System.Windows.Forms.Panel panel2;
        private System.Windows.Forms.PictureBox exportEVTbtn;
        private System.Windows.Forms.Label line;
        private System.Windows.Forms.TextBox EvtPath_txtBx;
    }
}