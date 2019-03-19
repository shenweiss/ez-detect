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
            this.ExportEvtBtn = new System.Windows.Forms.Button();
            this.EvtPath_txtBx = new System.Windows.Forms.TextBox();
            this.EVTExportLabel = new System.Windows.Forms.Label();
            this.panel2 = new System.Windows.Forms.Panel();
            this.panel2.SuspendLayout();
            this.SuspendLayout();
            // 
            // Evt_save_btn
            // 
            this.Evt_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.Evt_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Evt_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Evt_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Evt_save_btn.Location = new System.Drawing.Point(275, 215);
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
            // ExportEvtBtn
            // 
            this.ExportEvtBtn.BackgroundImage = ((System.Drawing.Image)(resources.GetObject("ExportEvtBtn.BackgroundImage")));
            this.ExportEvtBtn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.ExportEvtBtn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.ExportEvtBtn.Location = new System.Drawing.Point(308, 3);
            this.ExportEvtBtn.Name = "ExportEvtBtn";
            this.ExportEvtBtn.Size = new System.Drawing.Size(50, 51);
            this.ExportEvtBtn.TabIndex = 8;
            this.ExportEvtBtn.UseVisualStyleBackColor = true;
            this.ExportEvtBtn.Click += new System.EventHandler(this.ExportEvtBtn_Click);
            // 
            // EvtPath_txtBx
            // 
            this.EvtPath_txtBx.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.EvtPath_txtBx.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.EvtPath_txtBx.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.EvtPath_txtBx.Location = new System.Drawing.Point(0, 120);
            this.EvtPath_txtBx.Name = "EvtPath_txtBx";
            this.EvtPath_txtBx.Size = new System.Drawing.Size(360, 16);
            this.EvtPath_txtBx.TabIndex = 7;
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
            this.panel2.Controls.Add(this.Evt_save_btn);
            this.panel2.Controls.Add(this.EvtPath_txtBx);
            this.panel2.Controls.Add(this.ExportEvtBtn);
            this.panel2.Controls.Add(this.EVTExportLabel);
            this.panel2.Location = new System.Drawing.Point(55, 120);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 250);
            this.panel2.TabIndex = 11;
            // 
            // EVT
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(464, 473);
            this.Controls.Add(this.EVT_title);
            this.Controls.Add(this.panel2);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "EVT";
            this.Text = "EVT";
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button Evt_save_btn;
        private System.Windows.Forms.Label EVT_title;
        private System.Windows.Forms.Button ExportEvtBtn;
        private System.Windows.Forms.TextBox EvtPath_txtBx;
        private System.Windows.Forms.Label EVTExportLabel;
        private System.Windows.Forms.Panel panel2;
    }
}