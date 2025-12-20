<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MediaSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('Seeding media...');
        
        DB::table('media')->truncate();
        
        DB::table('media')->insert([
            [
                'id' => 1,
                'user_id' => 2,
                'disk' => 'cloudinary',
                'path' => 'documents/files/2/1766028765_Bonne_Bouche_Business_Profile.docx',
                'original_name' => 'Bonne_Bouche_Business_Profile.docx',
                'file_type' => 'docx',
                'mime_type' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'file_size' => 11636,
                'cloudinary_public_id' => 'documents/files/2/1766028765_Bonne_Bouche_Business_Profile.docx',
                'metadata' => json_encode([
                    'resource_type' => 'raw',
                    'folder' => 'documents/files/2',
                    'secure_url' => 'https://res.cloudinary.com/dbpnviwkw/raw/upload/v1766028768/documents/files/2/1766028765_Bonne_Bouche_Business_Profile.docx',
                    'format' => 'docx',
                    'width' => null,
                    'height' => null,
                ]),
                'created_at' => '2025-12-18 11:32:47',
                'updated_at' => '2025-12-18 11:32:56',
            ],
            [
                'id' => 2,
                'user_id' => 2,
                'disk' => 'cloudinary',
                'path' => 'documents/files/2/1766028793_Bonne_Bouche_Customer_Guide_FAQ.pdf',
                'original_name' => 'Bonne_Bouche_Customer_Guide_FAQ.pdf',
                'file_type' => 'pdf',
                'mime_type' => 'application/pdf',
                'file_size' => 7441,
                'cloudinary_public_id' => 'documents/files/2/1766028793_Bonne_Bouche_Customer_Guide_FAQ.pdf',
                'metadata' => json_encode([
                    'resource_type' => 'raw',
                    'folder' => 'documents/files/2',
                    'secure_url' => 'https://res.cloudinary.com/dbpnviwkw/raw/upload/v1766028796/documents/files/2/1766028793_Bonne_Bouche_Customer_Guide_FAQ.pdf',
                    'format' => 'pdf',
                    'width' => null,
                    'height' => null,
                ]),
                'created_at' => '2025-12-18 11:33:15',
                'updated_at' => '2025-12-18 11:33:19',
            ],
            [
                'id' => 3,
                'user_id' => 2,
                'disk' => 'cloudinary',
                'path' => 'documents/files/2/1766028803_Bonne_Bouche_Menu_Guide.md',
                'original_name' => 'Bonne_Bouche_Menu_Guide.md',
                'file_type' => 'md',
                'mime_type' => 'text/plain',
                'file_size' => 5906,
                'cloudinary_public_id' => 'documents/files/2/1766028803_Bonne_Bouche_Menu_Guide.md',
                'metadata' => json_encode([
                    'resource_type' => 'raw',
                    'folder' => 'documents/files/2',
                    'secure_url' => 'https://res.cloudinary.com/dbpnviwkw/raw/upload/v1766028806/documents/files/2/1766028803_Bonne_Bouche_Menu_Guide.md',
                    'format' => 'md',
                    'width' => null,
                    'height' => null,
                ]),
                'created_at' => '2025-12-18 11:33:25',
                'updated_at' => '2025-12-18 11:33:30',
            ],
            [
                'id' => 4,
                'user_id' => 2,
                'disk' => 'cloudinary',
                'path' => 'documents/files/2/1766028814_Bonne_Bouche_Quick_Reference.txt',
                'original_name' => 'Bonne_Bouche_Quick_Reference.txt',
                'file_type' => 'txt',
                'mime_type' => 'text/plain',
                'file_size' => 1594,
                'cloudinary_public_id' => 'documents/files/2/1766028814_Bonne_Bouche_Quick_Reference.txt',
                'metadata' => json_encode([
                    'resource_type' => 'raw',
                    'folder' => 'documents/files/2',
                    'secure_url' => 'https://res.cloudinary.com/dbpnviwkw/raw/upload/v1766028816/documents/files/2/1766028814_Bonne_Bouche_Quick_Reference.txt',
                    'format' => 'txt',
                    'width' => null,
                    'height' => null,
                ]),
                'created_at' => '2025-12-18 11:33:36',
                'updated_at' => '2025-12-18 11:33:37',
            ],
            [
                'id' => 5,
                'user_id' => 3,
                'disk' => 'cloudinary',
                'path' => 'documents/files/3/1766028834_JQ_Patisserie_About_Services.docx',
                'original_name' => 'JQ_Patisserie_About_Services.docx',
                'file_type' => 'docx',
                'mime_type' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'file_size' => 11986,
                'cloudinary_public_id' => 'documents/files/3/1766028834_JQ_Patisserie_About_Services.docx',
                'metadata' => json_encode([
                    'resource_type' => 'raw',
                    'folder' => 'documents/files/3',
                    'secure_url' => 'https://res.cloudinary.com/dbpnviwkw/raw/upload/v1766028837/documents/files/3/1766028834_JQ_Patisserie_About_Services.docx',
                    'format' => 'docx',
                    'width' => null,
                    'height' => null,
                ]),
                'created_at' => '2025-12-18 11:33:56',
                'updated_at' => '2025-12-18 11:33:58',
            ],
            [
                'id' => 6,
                'user_id' => 3,
                'disk' => 'cloudinary',
                'path' => 'documents/files/3/1766028842_JQ_Patisserie_Customer_FAQ.pdf',
                'original_name' => 'JQ_Patisserie_Customer_FAQ.pdf',
                'file_type' => 'pdf',
                'mime_type' => 'application/pdf',
                'file_size' => 7637,
                'cloudinary_public_id' => 'documents/files/3/1766028842_JQ_Patisserie_Customer_FAQ.pdf',
                'metadata' => json_encode([
                    'resource_type' => 'raw',
                    'folder' => 'documents/files/3',
                    'secure_url' => 'https://res.cloudinary.com/dbpnviwkw/raw/upload/v1766028845/documents/files/3/1766028842_JQ_Patisserie_Customer_FAQ.pdf',
                    'format' => 'pdf',
                    'width' => null,
                    'height' => null,
                ]),
                'created_at' => '2025-12-18 11:34:04',
                'updated_at' => '2025-12-18 11:34:08',
            ],
            [
                'id' => 7,
                'user_id' => 3,
                'disk' => 'cloudinary',
                'path' => 'documents/files/3/1766028853_JQ_Patisserie_Quick_Reference.txt',
                'original_name' => 'JQ_Patisserie_Quick_Reference.txt',
                'file_type' => 'txt',
                'mime_type' => 'text/plain',
                'file_size' => 1676,
                'cloudinary_public_id' => 'documents/files/3/1766028853_JQ_Patisserie_Quick_Reference.txt',
                'metadata' => json_encode([
                    'resource_type' => 'raw',
                    'folder' => 'documents/files/3',
                    'secure_url' => 'https://res.cloudinary.com/dbpnviwkw/raw/upload/v1766028855/documents/files/3/1766028853_JQ_Patisserie_Quick_Reference.txt',
                    'format' => 'txt',
                    'width' => null,
                    'height' => null,
                ]),
                'created_at' => '2025-12-18 11:34:14',
                'updated_at' => '2025-12-18 11:34:16',
            ],
        ]);
        
        DB::statement("SELECT setval('media_id_seq', COALESCE((SELECT MAX(id) FROM media), 1))");
        
        $this->command->info('✓ Seeded 7 media records.');
    }
}