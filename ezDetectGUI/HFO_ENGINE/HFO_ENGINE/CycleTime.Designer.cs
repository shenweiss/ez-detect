namespace HFO_ENGINE
{
    partial class CycleTime
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
            this.Times_title = new System.Windows.Forms.Label();
            this.Parallel_chk_bx = new System.Windows.Forms.CheckBox();
            this.c_time_1_rBtn = new System.Windows.Forms.RadioButton();
            this.c_time_2_rBtn = new System.Windows.Forms.RadioButton();
            this.c_time_3_rBtn = new System.Windows.Forms.RadioButton();
            this.c_time_4_rBtn = new System.Windows.Forms.RadioButton();
            this.CycleTime_save_btn = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.panel1 = new System.Windows.Forms.Panel();
            this.panel3 = new System.Windows.Forms.Panel();
            this.panel2.SuspendLayout();
            this.panel1.SuspendLayout();
            this.panel3.SuspendLayout();
            this.SuspendLayout();
            // 
            // Times_title
            // 
            this.Times_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Times_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Times_title.Location = new System.Drawing.Point(45, 55);
            this.Times_title.Name = "Times_title";
            this.Times_title.Size = new System.Drawing.Size(189, 40);
            this.Times_title.TabIndex = 2;
            this.Times_title.Text = "Cycle time";
            // 
            // Parallel_chk_bx
            // 
            this.Parallel_chk_bx.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.Parallel_chk_bx.AutoSize = true;
            this.Parallel_chk_bx.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Parallel_chk_bx.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Parallel_chk_bx.Location = new System.Drawing.Point(7, 20);
            this.Parallel_chk_bx.Name = "Parallel_chk_bx";
            this.Parallel_chk_bx.Size = new System.Drawing.Size(160, 24);
            this.Parallel_chk_bx.TabIndex = 3;
            this.Parallel_chk_bx.Text = "Parallel processing";
            this.Parallel_chk_bx.UseVisualStyleBackColor = true;
            this.Parallel_chk_bx.CheckedChanged += new System.EventHandler(this.Parallel_chk_bx_CheckedChanged);
            // 
            // c_time_1_rBtn
            // 
            this.c_time_1_rBtn.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.c_time_1_rBtn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.c_time_1_rBtn.Location = new System.Drawing.Point(29, 6);
            this.c_time_1_rBtn.Name = "c_time_1_rBtn";
            this.c_time_1_rBtn.Size = new System.Drawing.Size(85, 40);
            this.c_time_1_rBtn.TabIndex = 4;
            this.c_time_1_rBtn.TabStop = true;
            this.c_time_1_rBtn.Text = "5";
            this.c_time_1_rBtn.UseVisualStyleBackColor = true;
            // 
            // c_time_2_rBtn
            // 
            this.c_time_2_rBtn.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.c_time_2_rBtn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.c_time_2_rBtn.Location = new System.Drawing.Point(29, 52);
            this.c_time_2_rBtn.Name = "c_time_2_rBtn";
            this.c_time_2_rBtn.Size = new System.Drawing.Size(85, 40);
            this.c_time_2_rBtn.TabIndex = 5;
            this.c_time_2_rBtn.TabStop = true;
            this.c_time_2_rBtn.Text = "8";
            this.c_time_2_rBtn.UseVisualStyleBackColor = true;
            // 
            // c_time_3_rBtn
            // 
            this.c_time_3_rBtn.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.c_time_3_rBtn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.c_time_3_rBtn.Location = new System.Drawing.Point(29, 98);
            this.c_time_3_rBtn.Name = "c_time_3_rBtn";
            this.c_time_3_rBtn.Size = new System.Drawing.Size(85, 40);
            this.c_time_3_rBtn.TabIndex = 6;
            this.c_time_3_rBtn.TabStop = true;
            this.c_time_3_rBtn.Text = "10";
            this.c_time_3_rBtn.UseVisualStyleBackColor = true;
            // 
            // c_time_4_rBtn
            // 
            this.c_time_4_rBtn.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.c_time_4_rBtn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.c_time_4_rBtn.Location = new System.Drawing.Point(29, 144);
            this.c_time_4_rBtn.Name = "c_time_4_rBtn";
            this.c_time_4_rBtn.Size = new System.Drawing.Size(85, 40);
            this.c_time_4_rBtn.TabIndex = 7;
            this.c_time_4_rBtn.TabStop = true;
            this.c_time_4_rBtn.Text = "15";
            this.c_time_4_rBtn.UseVisualStyleBackColor = true;
            // 
            // CycleTime_save_btn
            // 
            this.CycleTime_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.CycleTime_save_btn.FlatAppearance.BorderSize = 2;
            this.CycleTime_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.CycleTime_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.CycleTime_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.CycleTime_save_btn.Location = new System.Drawing.Point(278, 286);
            this.CycleTime_save_btn.Name = "CycleTime_save_btn";
            this.CycleTime_save_btn.Size = new System.Drawing.Size(82, 34);
            this.CycleTime_save_btn.TabIndex = 11;
            this.CycleTime_save_btn.Text = "Save";
            this.CycleTime_save_btn.UseVisualStyleBackColor = true;
            this.CycleTime_save_btn.Click += new System.EventHandler(this.CycleTime_save_btn_Click);
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.panel1);
            this.panel2.Controls.Add(this.CycleTime_save_btn);
            this.panel2.Controls.Add(this.panel3);
            this.panel2.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.panel2.Location = new System.Drawing.Point(55, 150);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 320);
            this.panel2.TabIndex = 12;
            // 
            // panel1
            // 
            this.panel1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.panel1.Controls.Add(this.Parallel_chk_bx);
            this.panel1.Location = new System.Drawing.Point(0, 0);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(200, 63);
            this.panel1.TabIndex = 12;
            this.panel1.Paint += new System.Windows.Forms.PaintEventHandler(this.panel1_Paint);
            // 
            // panel3
            // 
            this.panel3.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.panel3.Controls.Add(this.c_time_2_rBtn);
            this.panel3.Controls.Add(this.c_time_3_rBtn);
            this.panel3.Controls.Add(this.c_time_4_rBtn);
            this.panel3.Controls.Add(this.c_time_1_rBtn);
            this.panel3.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.panel3.Location = new System.Drawing.Point(41, 81);
            this.panel3.Name = "panel3";
            this.panel3.Size = new System.Drawing.Size(200, 190);
            this.panel3.TabIndex = 13;
            // 
            // CycleTime
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.Times_title);
            this.Controls.Add(this.panel2);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "CycleTime";
            this.Text = "CycleTime";
            this.panel2.ResumeLayout(false);
            this.panel1.ResumeLayout(false);
            this.panel1.PerformLayout();
            this.panel3.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label Times_title;
        private System.Windows.Forms.CheckBox Parallel_chk_bx;
        private System.Windows.Forms.RadioButton c_time_1_rBtn;
        private System.Windows.Forms.RadioButton c_time_2_rBtn;
        private System.Windows.Forms.RadioButton c_time_3_rBtn;
        private System.Windows.Forms.RadioButton c_time_4_rBtn;
        private System.Windows.Forms.Button CycleTime_save_btn;
        private System.Windows.Forms.Panel panel2;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.Panel panel3;
    }
}