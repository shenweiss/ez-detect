namespace HFO_ENGINE
{
    partial class EEG
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(EEG));
            this.trcImportLabel = new System.Windows.Forms.Label();
            this.TrcPath_txtBx = new System.Windows.Forms.TextBox();
            this.importTRCbtn = new System.Windows.Forms.Button();
            this.EEG_title = new System.Windows.Forms.Label();
            this.EEG_save_btn = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.panel2.SuspendLayout();
            this.SuspendLayout();
            // 
            // trcImportLabel
            // 
            this.trcImportLabel.BackColor = System.Drawing.Color.Transparent;
            this.trcImportLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.trcImportLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.trcImportLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.trcImportLabel.Location = new System.Drawing.Point(0, 0);
            this.trcImportLabel.Name = "trcImportLabel";
            this.trcImportLabel.Size = new System.Drawing.Size(140, 26);
            this.trcImportLabel.TabIndex = 1;
            this.trcImportLabel.Text = "Import TRC file";
            // 
            // TrcPath_txtBx
            // 
            this.TrcPath_txtBx.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.TrcPath_txtBx.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.TrcPath_txtBx.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.TrcPath_txtBx.Location = new System.Drawing.Point(0, 120);
            this.TrcPath_txtBx.Name = "TrcPath_txtBx";
            this.TrcPath_txtBx.Size = new System.Drawing.Size(360, 16);
            this.TrcPath_txtBx.TabIndex = 2;
            // 
            // importTRCbtn
            // 
            this.importTRCbtn.BackgroundImage = ((System.Drawing.Image)(resources.GetObject("importTRCbtn.BackgroundImage")));
            this.importTRCbtn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.importTRCbtn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.importTRCbtn.Location = new System.Drawing.Point(308, 3);
            this.importTRCbtn.Name = "importTRCbtn";
            this.importTRCbtn.Size = new System.Drawing.Size(50, 51);
            this.importTRCbtn.TabIndex = 3;
            this.importTRCbtn.UseVisualStyleBackColor = true;
            this.importTRCbtn.Click += new System.EventHandler(this.ImportTRCbtn_Click);
            // 
            // EEG_title
            // 
            this.EEG_title.BackColor = System.Drawing.Color.Transparent;
            this.EEG_title.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.EEG_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.EEG_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.EEG_title.Location = new System.Drawing.Point(45, 55);
            this.EEG_title.Name = "EEG_title";
            this.EEG_title.Size = new System.Drawing.Size(148, 37);
            this.EEG_title.TabIndex = 4;
            this.EEG_title.Text = "Data source";
            // 
            // EEG_save_btn
            // 
            this.EEG_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.EEG_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.EEG_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.EEG_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.EEG_save_btn.Location = new System.Drawing.Point(275, 215);
            this.EEG_save_btn.Name = "EEG_save_btn";
            this.EEG_save_btn.Size = new System.Drawing.Size(82, 34);
            this.EEG_save_btn.TabIndex = 5;
            this.EEG_save_btn.Text = "Save";
            this.EEG_save_btn.UseVisualStyleBackColor = true;
            this.EEG_save_btn.Click += new System.EventHandler(this.EEG_save_btn_Click);
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.trcImportLabel);
            this.panel2.Controls.Add(this.importTRCbtn);
            this.panel2.Controls.Add(this.EEG_save_btn);
            this.panel2.Controls.Add(this.TrcPath_txtBx);
            this.panel2.Location = new System.Drawing.Point(55, 120);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 250);
            this.panel2.TabIndex = 9;
            // 
            // EEG
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.AutoSize = true;
            this.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.EEG_title);
            this.Controls.Add(this.panel2);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "EEG";
            this.Text = "EEG";
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label trcImportLabel;
        private System.Windows.Forms.TextBox TrcPath_txtBx;
        private System.Windows.Forms.Button importTRCbtn;
        private System.Windows.Forms.Label EEG_title;
        private System.Windows.Forms.Button EEG_save_btn;
        private System.Windows.Forms.Panel panel2;
    }
}