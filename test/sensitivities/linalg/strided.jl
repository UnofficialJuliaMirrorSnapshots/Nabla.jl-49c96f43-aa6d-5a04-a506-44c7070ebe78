@testset "Strided" begin

    let rng = MersenneTwister(123456), N = 100

        # Test strided matrix-matrix multiplication sensitivities.
        for (TA, TB, tCA, tDA, CA, DA, tCB, tDB, CB, DB) in Nabla.strided_matmul
            A, B, VA, VB = randn.(Ref(rng), [N, N, N, N], [N, N, N, N])
            @test check_errs(*, A * B, (A, B), (VA, VB))
        end
    end
end
