<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DocumentsTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('documents')->insert([
            [
                'id' => 1,
                'user_id' => 2,
                'original_name' => 'Bonne_Bouche_Business_Profile.docx',
                'status' => 'completed',
                'chunks_count' => 2,
                'error_message' => null,
                'created_at' => '2025-12-17 18:42:38',
                'updated_at' => '2025-12-17 18:42:41',
                'media_id' => 1,
            ],
            [
                'id' => 2,
                'user_id' => 2,
                'original_name' => 'Bonne_Bouche_Customer_Guide_FAQ.pdf',
                'status' => 'completed',
                'chunks_count' => 3,
                'error_message' => null,
                'created_at' => '2025-12-17 18:42:48',
                'updated_at' => '2025-12-17 18:42:53',
                'media_id' => 2,
            ],
            [
                'id' => 3,
                'user_id' => 2,
                'original_name' => 'Bonne_Bouche_Menu_Guide.md',
                'status' => 'completed',
                'chunks_count' => 4,
                'error_message' => null,
                'created_at' => '2025-12-17 18:42:59',
                'updated_at' => '2025-12-17 18:43:03',
                'media_id' => 3,
            ],
            [
                'id' => 4,
                'user_id' => 2,
                'original_name' => 'Bonne_Bouche_Quick_Reference.txt',
                'status' => 'completed',
                'chunks_count' => 1,
                'error_message' => null,
                'created_at' => '2025-12-17 18:43:09',
                'updated_at' => '2025-12-17 18:43:11',
                'media_id' => 4,
            ],
            [
                'id' => 5,
                'user_id' => 3,
                'original_name' => 'JQ_Patisserie_About_Services.docx',
                'status' => 'completed',
                'chunks_count' => 2,
                'error_message' => null,
                'created_at' => '2025-12-17 19:51:15',
                'updated_at' => '2025-12-17 19:51:19',
                'media_id' => 5,
            ],
            [
                'id' => 6,
                'user_id' => 3,
                'original_name' => 'JQ_Patisserie_Customer_FAQ.pdf',
                'status' => 'completed',
                'chunks_count' => 3,
                'error_message' => null,
                'created_at' => '2025-12-17 19:51:25',
                'updated_at' => '2025-12-17 19:51:29',
                'media_id' => 6,
            ],
            [
                'id' => 7,
                'user_id' => 3,
                'original_name' => 'JQ_Patisserie_Quick_Reference.txt',
                'status' => 'completed',
                'chunks_count' => 1,
                'error_message' => null,
                'created_at' => '2025-12-17 19:51:34',
                'updated_at' => '2025-12-17 19:51:36',
                'media_id' => 7,
            ],
        ]);
    }
}